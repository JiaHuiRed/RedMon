use base64::Engine;
use serde_json::Value;
use std::fs;
use std::path::Path;

/// Read a JSON file and return its contents as a Value.
#[tauri::command]
fn read_json(path: String) -> Result<Value, String> {
    let content = fs::read_to_string(&path)
        .map_err(|e| format!("读取文件失败 {}: {}", path, e))?;
    serde_json::from_str(&content)
        .map_err(|e| format!("解析JSON失败 {}: {}", path, e))
}

/// Write a Value to a JSON file.
#[tauri::command]
fn write_json(path: String, data: Value) -> Result<(), String> {
    let content = serde_json::to_string_pretty(&data)
        .map_err(|e| format!("序列化JSON失败: {}", e))?;
    fs::write(&path, &content)
        .map_err(|e| format!("写入文件失败 {}: {}", path, e))?;
    Ok(())
}

/// Read an image file and return as base64 data URL.
#[tauri::command]
fn read_sprite(path: String) -> Result<String, String> {
    let img = image::open(&path)
        .map_err(|e| format!("打开图片失败 {}: {}", path, e))?;

    let mut buf = std::io::Cursor::new(Vec::new());
    img.write_to(&mut buf, image::ImageFormat::Png)
        .map_err(|e| format!("编码PNG失败: {}", e))?;

    let b64 = base64::engine::general_purpose::STANDARD.encode(buf.into_inner());
    Ok(format!("data:image/png;base64,{}", b64))
}

/// List files in a directory matching a pattern.
#[tauri::command]
fn list_files(dir: String, ext: String) -> Result<Vec<String>, String> {
    let dir_path = Path::new(&dir);
    if !dir_path.exists() {
        return Ok(Vec::new());
    }
    let mut files = Vec::new();
    for entry in fs::read_dir(dir_path).map_err(|e| format!("读取目录失败 {}: {}", dir, e))? {
        let entry = entry.map_err(|e| format!("读取条目失败: {}", e))?;
        let path = entry.path();
        if path.is_file() {
            if let Some(e) = path.extension() {
                if e.to_string_lossy().to_lowercase() == ext.to_lowercase() {
                    if let Some(name) = path.file_stem() {
                        files.push(name.to_string_lossy().to_string());
                    }
                }
            }
        }
    }
    files.sort();
    Ok(files)
}

/// Auto-detect project root by walking up from exe/CWD looking for data/species.json.
#[tauri::command]
fn detect_project_root() -> Result<serde_json::Value, String> {
    // Walk up from executable directory
    if let Ok(exe) = std::env::current_exe() {
        if let Some(parent) = exe.parent() {
            if let Some(root) = find_project_root(parent) {
                return Ok(serde_json::json!({ "root": root }));
            }
        }
    }
    // Walk up from current working directory
    if let Ok(cwd) = std::env::current_dir() {
        if let Some(root) = find_project_root(&cwd) {
            return Ok(serde_json::json!({ "root": root }));
        }
    }
    Err("未找到项目目录（未检测到 data/species.json）".to_string())
}

fn find_project_root(start: &std::path::Path) -> Option<String> {
    let mut dir = Some(start);
    while let Some(path) = dir {
        if path.join("data").join("species.json").exists() {
            return Some(path.to_string_lossy().to_string());
        }
        dir = path.parent();
    }
    None
}

/// Open a dialog to select the project root directory.
#[tauri::command]
fn open_project(app_handle: tauri::AppHandle) -> Result<serde_json::Value, String> {
    use tauri_plugin_dialog::DialogExt;
    let dir = app_handle
        .dialog()
        .file()
        .blocking_pick_folder();

    match dir {
        Some(path) => {
            let root = path.to_string();
            validate_project_root(&root)?;
            Ok(serde_json::json!({ "root": root }))
        }
        None => Err("未选择目录".to_string()),
    }
}

/// Open a project root directly by path (no dialog).
#[tauri::command]
fn load_project(path: String) -> Result<serde_json::Value, String> {
    validate_project_root(&path)?;
    Ok(serde_json::json!({ "root": path }))
}

fn validate_project_root(root: &str) -> Result<(), String> {
    let data_path = std::path::Path::new(root).join("data");
    if !data_path.exists() {
        return Err(format!("所选目录不是有效的项目根目录（缺少 data/ 子目录）: {}", root));
    }
    Ok(())
}

/// Get standard data file paths for a project root.
#[tauri::command]
fn get_data_paths(root: String) -> Result<serde_json::Value, String> {
    let base = Path::new(&root).join("data");
    let files = vec![
        ("species", "species.json"),
        ("moves", "moves.json"),
        ("items", "items.json"),
        ("abilities", "abilities.json"),
        ("npcs", "npcs.json"),
        ("dialogs", "dialogs.json"),
        ("maps", "maps.json"),
    ];

    let mut result = serde_json::Map::new();
    for (key, filename) in files {
        let path = base.join(filename);
        let exists = path.exists();
        result.insert(
            key.to_string(),
            serde_json::json!({
                "path": path.to_string_lossy(),
                "exists": exists
            }),
        );
    }

    // Also include sprite directories
    let sprites_dir = Path::new(&root).join("assets").join("sprites");
    result.insert(
        "sprites_dir".to_string(),
        serde_json::json!({
            "path": sprites_dir.to_string_lossy(),
            "exists": sprites_dir.exists()
        }),
    );

    let npc_sprites_dir = Path::new(&root).join("assets").join("npc");
    result.insert(
        "npc_sprites_dir".to_string(),
        serde_json::json!({
            "path": npc_sprites_dir.to_string_lossy(),
            "exists": npc_sprites_dir.exists()
        }),
    );

    let items_dir = Path::new(&root).join("assets").join("ui").join("items");
    result.insert(
        "items_dir".to_string(),
        serde_json::json!({
            "path": items_dir.to_string_lossy(),
            "exists": items_dir.exists()
        }),
    );

    Ok(Value::Object(result))
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .invoke_handler(tauri::generate_handler![
            read_json,
            write_json,
            read_sprite,
            list_files,
            open_project,
            load_project,
            detect_project_root,
            get_data_paths,
        ])
        .run(tauri::generate_context!())
        .expect("启动 RedMon Editor 失败");
}
