import { invoke } from "@tauri-apps/api/core";

export async function readJson(path) {
  return await invoke("read_json", { path });
}

export async function writeJson(path, data) {
  return await invoke("write_json", { path, data });
}

export async function readSprite(path) {
  return await invoke("read_sprite", { path });
}

export async function listFiles(dir, ext) {
  return await invoke("list_files", { dir, ext });
}

export async function openProject() {
  return await invoke("open_project");
}

export async function loadProject(path) {
  return await invoke("load_project", { path });
}

export async function detectProjectRoot() {
  return await invoke("detect_project_root");
}

export async function getDataPaths(root) {
  return await invoke("get_data_paths", { root });
}
