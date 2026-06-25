"""
RedMon 图鉴 & 技能编辑器
用法: python -X utf8 tools/mon_editor.py
浏览器自动打开 http://localhost:8765
Ctrl+C 停止
"""

import json, os, sys, threading, webbrowser
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

# 打包为 exe 时 exe 在 tools/dist/，需多回溯一层
if getattr(sys, "frozen", False):
    BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(sys.executable))))
else:
    BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPECIES_FILE = os.path.join(BASE_DIR, "data", "species.json")
MOVES_FILE   = os.path.join(BASE_DIR, "data", "moves.json")
PORT = 8765

HTML = """\
<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<title>RedMon 编辑器</title>
<style>
:root{
  --bg:#0d0d1c;--bg2:#14142a;--bg3:#1e1e3a;--bg4:#111120;
  --bd:#2a2a50;--bd2:#1c1c38;--bd3:#222240;
  --tx:#dde;--tx2:#aab;--tx3:#7788aa;--tx4:#99aacc;
  --in-bg:#0d0d22;--in-bd:#3a3a60;
  --hover:#1c1c38;--sel:#232348;
  --empty:#3a3a5a;--nobadge:#2a2a48;
  --accent:#ffd055;
}
body.light{
  --bg:#f2f2fa;--bg2:#e4e4f4;--bg3:#d4d4ec;--bg4:#eaeaf8;
  --bd:#b0b0d0;--bd2:#c8c8e0;--bd3:#c0c0d8;
  --tx:#1a1a3a;--tx2:#44446a;--tx3:#66669a;--tx4:#55559a;
  --in-bg:#ffffff;--in-bd:#a0a0c0;
  --hover:#d4d4ec;--sel:#c4c4e4;
  --empty:#9090aa;--nobadge:#d4d4e8;
  --accent:#5500cc;
}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:"Microsoft YaHei","SimHei",sans-serif;background:var(--bg);color:var(--tx);
     height:100vh;display:flex;flex-direction:column;font-size:13px;transition:background .2s,color .2s}
.topbar{background:var(--bg2);padding:8px 16px;display:flex;align-items:center;
        gap:10px;border-bottom:2px solid var(--bd);flex-shrink:0}
.topbar h1{font-size:15px;color:var(--accent);white-space:nowrap;margin-right:6px}
.tabs{display:flex;gap:2px;margin-right:10px}
.tab{padding:5px 16px;border-radius:4px 4px 0 0;cursor:pointer;font-size:12px;
     background:var(--bg3);color:var(--tx3);border:1px solid var(--bd);border-bottom:none}
.tab.on{background:var(--bg);color:var(--accent);border-color:var(--bd)}
.topbar input,.topbar select{background:var(--in-bg);border:1px solid var(--in-bd);color:var(--tx);
  padding:5px 9px;border-radius:4px;font-size:12px;font-family:inherit}
.topbar input{flex:1;min-width:0}
.btn{padding:5px 13px;border-radius:4px;border:none;cursor:pointer;
     font-size:12px;font-family:inherit;font-weight:bold}
.btn-new{background:#3a5fd9;color:#fff}.btn-new:hover{background:#4a6fe9}
.btn-save{background:#1d8a4a;color:#fff}.btn-save:hover{background:#2aad5c}
.btn-edit{background:#2a3a7a;color:#bcd}.btn-edit:hover{background:#3a4a8a}
.btn-del{background:#7a1a1a;color:#fcc}.btn-del:hover{background:#a02020}
.btn-back{background:var(--bg3);color:var(--tx2)}.btn-back:hover{background:var(--hover)}
.btn-theme{background:var(--bg3);color:var(--tx2);border:1px solid var(--bd);
           padding:4px 10px;border-radius:4px;cursor:pointer;font-size:13px;font-family:inherit}
.btn-sm{padding:2px 8px;font-size:11px}
.cnt{color:var(--tx3);font-size:11px;white-space:nowrap}
.pane{display:flex;flex:1;overflow:hidden}
.pane.hidden{display:none}
.lp{width:200px;flex:0 0 200px;background:var(--bg4);border-right:2px solid var(--bd3);overflow-y:auto}
.si{padding:7px 10px;cursor:pointer;border-bottom:1px solid var(--bd2);
    display:flex;align-items:center;gap:6px}
.si:hover{background:var(--hover)}
.si.on{background:var(--sel);border-left:3px solid #4a6cf7}
.sn{flex:1;font-size:13px}
.no-item{padding:16px;color:var(--tx3);font-size:12px;text-align:center}
.ttag{font-size:9px;padding:1px 5px;border-radius:3px;color:#fff;font-weight:bold}
.dp{flex:1;overflow-y:auto;padding:20px}
.empty{display:flex;flex-direction:column;align-items:center;justify-content:center;
       height:70%;color:var(--empty);gap:10px}
.sec{font-size:10px;color:var(--tx3);text-transform:uppercase;letter-spacing:1px;
     margin:14px 0 8px;border-bottom:1px solid var(--bd3);padding-bottom:3px}
.actions{display:flex;gap:8px;margin-bottom:14px}
.info-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin-bottom:14px}
.icard{background:var(--bg2);padding:8px 12px;border-radius:6px}
.ilbl{font-size:10px;color:var(--tx3);margin-bottom:2px}
.ival{font-size:13px;color:var(--tx)}
.stat-tbl{width:100%;border-collapse:collapse;margin-bottom:14px}
.stat-tbl th{padding:5px 9px;font-size:11px;color:var(--tx2);background:var(--bg2);text-align:center}
.stat-tbl th:first-child{text-align:left}
.stat-tbl td{padding:5px 8px;border-bottom:1px solid var(--bd2);vertical-align:middle}
.sname{font-size:12px;color:var(--tx4);white-space:nowrap}
.sval{font-size:13px;font-weight:bold;text-align:right;width:34px}
.bar-cell{width:150px}
.sbar{height:14px;background:var(--bg3);border-radius:3px;overflow:hidden}
.sfill{height:100%;border-radius:3px}
.rc{text-align:center;font-size:12px;color:var(--tx2);width:88px}
.total-row td{font-size:12px;color:var(--accent);font-weight:bold;padding:5px 8px;
              background:var(--bg2);border-top:1px solid var(--bd)}
.sc-hp{background:#ff7f7f}.sc-atk{background:#f5a86e}.sc-def{background:#f5d76e}
.sc-spa{background:#9eb4f5}.sc-spd2{background:#a0e090}.sc-spd{background:#e09af5}
.ls-tbl{width:100%;border-collapse:collapse;margin-bottom:14px}
.ls-tbl th{padding:5px 9px;font-size:11px;color:var(--tx2);background:var(--bg2);
           text-align:center;white-space:nowrap}
.ls-tbl th:nth-child(1),.ls-tbl th:nth-child(2){text-align:left}
.ls-tbl td{padding:5px 8px;border-bottom:1px solid var(--bd2);
           text-align:center;vertical-align:middle;font-size:12px}
.ls-tbl td:nth-child(1),.ls-tbl td:nth-child(2){text-align:left}
.ls-tbl tr:hover td{background:var(--hover)}
.lvbadge{background:var(--nobadge);padding:2px 6px;border-radius:3px;
         font-size:11px;color:var(--tx4);display:inline-block}
.mv-name{font-weight:bold;color:var(--tx)}
.cat-phy{background:#c83000;color:#fff;padding:1px 7px;border-radius:3px;font-size:11px}
.cat-spe{background:#0840b0;color:#fff;padding:1px 7px;border-radius:3px;font-size:11px}
.cat-sta{background:#406040;color:#dde;padding:1px 7px;border-radius:3px;font-size:11px}
.mv-item{padding:6px 10px;cursor:pointer;border-bottom:1px solid var(--bd2);
         display:flex;align-items:center;gap:6px}
.mv-item:hover{background:var(--hover)}
.mv-item.on{background:var(--sel);border-left:3px solid #4a6cf7}
.mv-cat-dot{width:8px;height:8px;border-radius:50%;flex-shrink:0}
.fgrid{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:14px}
.fg{display:flex;flex-direction:column;gap:4px}
.fg.full{grid-column:1/-1}
.flbl{font-size:10px;color:var(--tx3)}
.fin{background:var(--bg2);border:1px solid var(--bd);color:var(--tx);
     padding:7px 10px;border-radius:4px;font-size:13px;font-family:inherit;width:100%}
.fin:focus{outline:none;border-color:#4a6cf7}
select.fin{cursor:pointer}
.stat6{display:grid;grid-template-columns:repeat(6,1fr);gap:8px}
.stg{display:flex;flex-direction:column;gap:3px;align-items:center}
.stg label{font-size:10px;color:var(--tx3)}
.stg input{text-align:center;width:100%}
.ls-rows{display:flex;flex-direction:column;gap:6px;margin-bottom:8px}
.ls-row{display:flex;gap:6px;align-items:center}
.ls-row input:first-child{width:64px}
::-webkit-scrollbar{width:5px}
::-webkit-scrollbar-track{background:var(--bg)}
::-webkit-scrollbar-thumb{background:var(--bd);border-radius:3px}
</style>
</head>
<body>
<div class="topbar">
  <h1>RedMon</h1>
  <div class="tabs">
    <div class="tab on" id="tab-mon"  onclick="switchTab('mon')">&#x7CBE;&#x7075;</div>
    <div class="tab"    id="tab-move" onclick="switchTab('move')">&#x6280;&#x80FD;</div>
  </div>
  <input type="text" id="srch" placeholder="&#x641C;&#x7D22;&#x2026;">
  <select id="tflt"><option value="">&#x6240;&#x6709;&#x5C5E;&#x6027;</option></select>
  <select id="cflt" class="hidden"><option value="">&#x6240;&#x6709;&#x5206;&#x7C7B;</option>
    <option>&#x7269;&#x7406;</option><option>&#x7279;&#x6B8A;</option><option>&#x53D8;&#x5316;</option>
  </select>
  <button class="btn btn-new" id="btnNew" onclick="openNew()">&#xFF0B; &#x65B0;&#x5EFA;</button>
  <span class="cnt" id="cnt"></span>
  <button class="btn-theme" id="btnTheme" onclick="toggleTheme()">&#x2600;&#xFE0F;</button>
</div>
<!-- ═══ SPECIES PANE ═══ -->
<div class="pane" id="pane-mon">
  <div class="lp" id="monList"></div>
  <div class="dp" id="monDp"><div class="empty"><div style="font-size:48px">&#x1F50D;</div>
    <div>&#x4ECE;&#x5DE6;&#x4FA7;&#x9009;&#x62E9;&#x7CBE;&#x7075;</div></div></div>
</div>
<!-- ═══ MOVES PANE ═══ -->
<div class="pane hidden" id="pane-move">
  <div class="lp" id="moveList"></div>
  <div class="dp" id="moveDp"><div class="empty"><div style="font-size:48px">&#x2728;</div>
    <div>&#x4ECE;&#x5DE6;&#x4FA7;&#x9009;&#x62E9;&#x6280;&#x80FD;</div></div></div>
</div>

<script>
window.onerror=function(msg,src,line,col,err){
  document.body.insertAdjacentHTML('afterbegin',
    '<div style="background:red;color:#fff;padding:10px;font-size:13px;z-index:9999;position:fixed;top:0;left:0;right:0">'+
    'JS Error: '+msg+' (line '+line+')</div>');
  return false;
};
/* ── constants ────────────────────────────────────────────────────────────── */
const TYPES=["","\u7a7a","\u706b","\u6c34","\u6728","\u96f7","\u51b0","\u683c",
  "\u6bd2","\u571f","\u98ce","\u7075","\u866b","\u5ca9","\u9b3c","\u9f99","\u6697","\u9494","\u4ed9"];
const TC={"\u7a7a":"#909090","\u706b":"#e06010","\u6c34":"#2880e0","\u6728":"#18a040",
  "\u96f7":"#c8a808","\u51b0":"#48c0e0","\u683c":"#b01818","\u6bd2":"#8018b0",
  "\u571f":"#906808","\u98ce":"#60a8d8","\u7075":"#c81080","\u866b":"#58a018",
  "\u5ca9":"#806820","\u9b3c":"#483068","\u9f99":"#0818a0","\u6697":"#282828",
  "\u9494":"#787888","\u4ed9":"#e070a0"};
const CATS=["\u7269\u7406","\u7279\u6b8a","\u53d8\u5316"];
const CATCLS={"\u7269\u7406":"cat-phy","\u7279\u6b8a":"cat-spe","\u53d8\u5316":"cat-sta"};
const CATDOT={"\u7269\u7406":"#c83000","\u7279\u6b8a":"#0840b0","\u53d8\u5214":"#406040","\u53d8\u5316":"#406040"};
const EFFECTS=[
  ["","(\u65e0)"],["lower_atk","\u964d\u653b\u51fb"],["lower_def","\u964d\u9632\u5fa1"],
  ["lower_acc","\u964d\u547d\u4e2d"],["lower_spd","\u964d\u901f\u5ea6"],
  ["raise_atk","\u5347\u653b\u51fb"],["raise_def","\u5347\u9632\u5fa1"],
  ["raise_sp_atk","\u5347\u7279\u653b"],["raise_spd","\u5347\u901f\u5ea6"],
  ["inflict_burn","\u70e7\u4f24"],["inflict_poison","\u4e2d\u6bd2"],
  ["inflict_paralysis","\u9ebb\u75f9"],["inflict_freeze","\u51b0\u5c01"],
  ["inflict_sleep","\u5750\u7720"]
];
const SN=["hp","atk","def","sp_atk","sp_def","spd"];
const SL={hp:"HP",atk:"\u653b\u51fb",def:"\u9632\u5fa1",sp_atk:"\u7279\u653b",sp_def:"\u7279\u9632",spd:"\u901f\u5ea6"};
const SC={hp:"sc-hp",atk:"sc-atk",def:"sc-def",sp_atk:"sc-spa",sp_def:"sc-spd2",spd:"sc-spd"};
const GR=["\u5feb\u901f","\u4e2d\u901f","\u7f13\u6162"];

let species={}, moves={}, selMon=null, selMov=null, curTab="mon";

/* ── Theme ───────────────────────────────────────────────────────────────── */
function toggleTheme(){
  const light=document.body.classList.toggle("light");
  document.getElementById("btnTheme").innerHTML=light?"&#x1F319;":"&#x2600;&#xFE0F;";
  localStorage.setItem("theme",light?"light":"dark");
}
(function(){
  if(localStorage.getItem("theme")==="light"){
    document.body.classList.add("light");
    document.getElementById("btnTheme").innerHTML="&#x1F319;";
  }
})();

/* ── API ─────────────────────────────────────────────────────────────────── */
async function load(){
  try{
    [species,moves]=await Promise.all([
      fetch("/api/species").then(r=>{if(!r.ok)throw new Error("species "+r.status);return r.json();}),
      fetch("/api/moves").then(r=>{if(!r.ok)throw new Error("moves "+r.status);return r.json();})
    ]);
  }catch(e){
    console.error("load failed:",e);
    document.getElementById("cnt").textContent="加载失败: "+e.message;
    return;
  }
  buildFilters(); renderList();
}
const saveSpecies=()=>fetch("/api/species",{method:"POST",
  headers:{"Content-Type":"application/json"},body:JSON.stringify(species)});
const saveMoves=()=>fetch("/api/moves",{method:"POST",
  headers:{"Content-Type":"application/json"},body:JSON.stringify(moves)});

/* ── Tab ─────────────────────────────────────────────────────────────────── */
function switchTab(t){
  curTab=t;
  document.getElementById("tab-mon").className="tab"+(t==="mon"?" on":"");
  document.getElementById("tab-move").className="tab"+(t==="move"?" on":"");
  document.getElementById("pane-mon").className="pane"+(t==="mon"?"":" hidden");
  document.getElementById("pane-move").className="pane"+(t==="move"?"":" hidden");
  document.getElementById("tflt").className=(t==="mon")?"":"hidden";
  document.getElementById("cflt").className=(t==="move")?"":"hidden";
  document.getElementById("btnNew").textContent=t==="mon"?"+ \u65b0\u5efa\u7cbe\u7075":"+ \u65b0\u5efa\u6280\u80fd";
  renderList();
}

/* ── Filters ─────────────────────────────────────────────────────────────── */
function buildFilters(){
  const ts=new Set();
  Object.values(species).forEach(s=>{if(s.type1)ts.add(s.type1);if(s.type2)ts.add(s.type2);});
  document.getElementById("tflt").innerHTML=
    '<option value="">\u6240\u6709\u5c5e\u6027</option>'+
    [...ts].sort().map(t=>`<option>${t}</option>`).join("");
}

/* ── renderList ──────────────────────────────────────────────────────────── */
function renderList(){
  if(curTab==="mon") renderMonList();
  else renderMoveList();
}
function renderMonList(){
  const q=document.getElementById("srch").value.toLowerCase();
  const tf=document.getElementById("tflt").value;
  const items=Object.entries(species).filter(([id,s])=>{
    if(q&&!id.toLowerCase().includes(q))return false;
    if(tf&&s.type1!==tf&&s.type2!==tf)return false;
    return true;
  });
  document.getElementById("cnt").textContent=items.length+"/"+Object.keys(species).length+" \u53ea";
  document.getElementById("monList").innerHTML=items.length
    ?items.map(([id,s])=>`<div class="si${id===selMon?" on":""}" onclick="pickMon('${id}')">
        <span class="sn">${id}</span>${ttag(s.type1)}${s.type2?ttag(s.type2):""}</div>`).join("")
    :"<div class='no-item'>\u65e0\u5339\u914d</div>";
}
function renderMoveList(){
  const q=document.getElementById("srch").value.toLowerCase();
  const cf=document.getElementById("cflt").value;
  const items=Object.entries(moves).filter(([id,m])=>{
    if(q&&!id.toLowerCase().includes(q))return false;
    if(cf&&m.category!==cf)return false;
    return true;
  });
  document.getElementById("cnt").textContent=items.length+"/"+Object.keys(moves).length+" \u4e2a";
  document.getElementById("moveList").innerHTML=items.length
    ?items.map(([id,m])=>{
        const dot=CATDOT[m.category]||"#666";
        return`<div class="mv-item${id===selMov?" on":""}" onclick="pickMov('${id}')">
          <span class="mv-cat-dot" style="background:${dot}"></span>
          <span class="sn">${id}</span>${ttag(m.type)}</div>`;
      }).join("")
    :"<div class='no-item'>\u65e0\u5339\u914d</div>";
}

function ttag(t,sz){
  if(!t)return"";
  const s=sz?`font-size:${sz}px;padding:3px 10px`:"";
  return`<span class="ttag" style="background:${TC[t]||"#666"};${s}">${t}</span>`;
}

/* ── Species detail ──────────────────────────────────────────────────────── */
function pickMon(id){selMon=id;renderMonList();renderMonDetail(id);}

function statRange(base,lv,isHp){
  const lo=isHp?Math.floor(3*base*lv/100)+lv+10:Math.floor(3*base*lv/100)+5;
  const hi=isHp?Math.floor((3*base+31)*lv/100)+lv+10:Math.floor((3*base+31)*lv/100)+5;
  return`${lo}&ndash;${hi}`;
}

function renderMonDetail(id){
  const s=species[id];if(!s)return;
  const b=s.base||{};
  const total=SN.reduce((a,k)=>a+(b[k]||0),0);
  const bars=SN.map(k=>{
    const v=b[k]||0,pct=Math.min(100,v/160*100);
    return`<tr>
      <td class="sname">${SL[k]}</td>
      <td class="sval">${v}</td>
      <td class="bar-cell"><div class="sbar">
        <div class="sfill ${SC[k]}" style="width:${pct}%"></div></div></td>
      <td class="rc">${statRange(v,50,k==="hp")}</td>
      <td class="rc">${statRange(v,100,k==="hp")}</td></tr>`;
  }).join("");
  const ls=s.learnset||{};
  const lvs=Object.keys(ls).map(Number).sort((a,b)=>a-b);
  const lsRows=lvs.flatMap(lv=>{
    const arr=ls[String(lv)]||ls[lv]||[];
    return arr.map(mn=>{
      const mv=moves[mn]||{};
      const pow=mv.power>0?`<b style="color:#f5d76e">${mv.power}</b>`:`<span style="color:#444">&mdash;</span>`;
      const acc=mv.accuracy?`<span style="color:#a0d8a0">${mv.accuracy}</span>`:`<span style="color:#444">&mdash;</span>`;
      const catH=mv.category?`<span class="${CATCLS[mv.category]||"cat-sta"}">${mv.category}</span>`:"";
      return`<tr>
        <td><span class="lvbadge">${lv===1?"\u2014":"Lv."+lv}</span></td>
        <td><span class="mv-name">${mn}</span></td>
        <td>${mv.type?ttag(mv.type):""}</td>
        <td>${catH}</td>
        <td>${pow}</td><td>${acc}</td>
        <td><span style="color:#a0c0e0">${mv.max_pp||"&mdash;"}</span></td></tr>`;
    });
  }).join("");
  let evo=`<span>${id}</span>`;
  if(s.evolves_into)
    evo+=`<span style="color:#5577aa;font-size:18px;margin:0 6px">&#x2192;</span>
      <span style="cursor:pointer;text-decoration:underline;color:#7799dd"
            onclick="pickMon('${s.evolves_into}')">${s.evolves_into}</span>
      <span style="font-size:11px;color:#7788aa"> @Lv.${s.evolve_level||"?"}</span>`;

  document.getElementById("monDp").innerHTML=`
    <div class="actions">
      <button class="btn btn-edit" onclick="openMonEdit('${id}')">&#x270F; \u7f16\u8f91</button>
      <button class="btn btn-del"  onclick="delMon('${id}')">&#x1F5D1; \u5220\u9664</button>
    </div>
    <div style="display:flex;align-items:baseline;gap:12px;margin-bottom:10px">
      <span style="font-size:22px;font-weight:bold;color:#ffd055">${id}</span>
      <span style="display:flex;gap:6px">${ttag(s.type1,14)}${s.type2?ttag(s.type2,14):""}</span>
    </div>
    <div style="font-size:12px;color:#8899bb;margin-bottom:14px;line-height:1.5">${s.desc||""}</div>
    <div class="info-grid">
      <div class="icard"><div class="ilbl">\u6355\u83b7\u7387</div><div class="ival">${s.catch_rate||"&mdash;"}</div></div>
      <div class="icard"><div class="ilbl">\u7ecf\u9a8c\u5956\u52b1</div><div class="ival">${s.exp_yield||"&mdash;"}</div></div>
      <div class="icard"><div class="ilbl">\u6210\u957f\u901f\u5ea6</div><div class="ival">${s.growth_rate||"&mdash;"}</div></div>
      <div class="icard"><div class="ilbl">\u6027\u522b\u6bd4</div><div class="ival">${s.gender_ratio||"&mdash;"}</div></div>
      <div class="icard"><div class="ilbl">\u4f53\u578b</div><div class="ival">${s.size_info||"&mdash;"}</div></div>
      <div class="icard"><div class="ilbl">\u8fdb\u5316</div><div class="ival">${s.evolves_into||"\u65e0"}</div></div>
    </div>
    <div class="sec">\u79cd\u65cf\u5024</div>
    <table class="stat-tbl">
      <thead><tr><th>\u79cd\u65cf\u5024</th><th></th>
        <th style="text-align:left">\u80fd\u529b\u6761</th>
        <th>Lv.50</th><th>Lv.100</th></tr></thead>
      <tbody>${bars}</tbody>
      <tr class="total-row"><td>\u603b\u548c</td>
        <td colspan="4"><b style="color:#ffd055">${total}</b></td></tr>
    </table>
    <div class="sec">\u8fdb\u5316\u94fe</div>
    <div style="display:flex;align-items:center;gap:10px;margin-bottom:14px">${evo}</div>
    <div class="sec">\u6280\u80fd\u8868</div>
    <table class="ls-tbl">
      <thead><tr><th>\u7b49\u7ea7</th><th>\u62db\u5f0f</th>
        <th>\u5c5e\u6027</th><th>\u5206\u7c7b</th>
        <th>\u5a01\u529b</th><th>\u547d\u4e2d</th><th>PP</th></tr></thead>
      <tbody>${lsRows||'<tr><td colspan="7" style="color:#444;text-align:center">\u6682\u65e0\u6570\u636e</td></tr>'}</tbody>
    </table>`;
}

/* ── Species form ────────────────────────────────────────────────────────── */
function openNew(){if(curTab==="mon")openMonNew();else openMovNew();}
function openMonNew(){selMon=null;renderMonList();renderMonForm(null);}
function openMonEdit(id){renderMonForm(id);}

function renderMonForm(id){
  const s=id?species[id]:{};
  const b=s.base||{hp:45,atk:50,def:45,sp_atk:50,sp_def:45,spd:50};
  const ls=s.learnset||{"1":[]};
  const to=TYPES.map(t=>`<option value="${t}"${(s.type1||"")==t?" selected":""}>${t||"(\u65e0)"}</option>`).join("");
  const to2=TYPES.map(t=>`<option value="${t}"${(s.type2||"")==t?" selected":""}>${t||"(\u65e0)"}</option>`).join("");
  const go=GR.map(g=>`<option${(s.growth_rate||"\u4e2d\u901f")==g?" selected":""}>${g}</option>`).join("");
  const lsH=Object.entries(ls).map(([lv,mvs])=>lsRow(lv,mvs.join(","))).join("");
  const stI=SN.map(k=>`<div class="stg"><label>${SL[k]}</label>
    <input id="f_${k}" class="fin" type="number" min="1" max="255" value="${b[k]||50}"></div>`).join("");
  document.getElementById("monDp").innerHTML=`
    <h2 style="color:#ffd055;margin-bottom:14px;font-size:15px">
      ${id?"\u7f16\u8f91 "+id:"\u65b0\u5efa\u7cbe\u7075"}</h2>
    <div class="fgrid">
      <div class="fg"><label class="flbl">\u540d\u79f0 *</label>
        <input id="f_name" class="fin" value="${s.name||id||""}" placeholder="\u7cbe\u7075\u540d\u79f0"></div>
      <div class="fg full"><label class="flbl">\u56fe\u9274\u8bf4\u660e</label>
        <input id="f_desc" class="fin" value="${(s.desc||"").replace(/"/g,"&quot;")}"></div>
      <div class="fg"><label class="flbl">\u5c5e\u6027 1 *</label>
        <select id="f_t1" class="fin">${to}</select></div>
      <div class="fg"><label class="flbl">\u5c5e\u6027 2</label>
        <select id="f_t2" class="fin">${to2}</select></div>
      <div class="fg"><label class="flbl">\u6027\u522b\u6bd4</label>
        <input id="f_gender" class="fin" value="${s.gender_ratio||"50/50"}"></div>
      <div class="fg"><label class="flbl">\u4f53\u578b</label>
        <input id="f_size" class="fin" value="${s.size_info||""}" placeholder="\u5c0f\u578b / 0.5m / 5.0kg"></div>
      <div class="fg"><label class="flbl">\u6355\u83b7\u7387</label>
        <input id="f_catch" class="fin" type="number" value="${s.catch_rate||45}"></div>
      <div class="fg"><label class="flbl">\u7ecf\u9a8c\u5956\u52b1</label>
        <input id="f_exp" class="fin" type="number" value="${s.exp_yield||64}"></div>
      <div class="fg"><label class="flbl">\u6210\u957f\u901f\u5ea6</label>
        <select id="f_gr" class="fin">${go}</select></div>
      <div class="fg"><label class="flbl">\u8fdb\u5316\u76ee\u6807</label>
        <input id="f_evo" class="fin" value="${s.evolves_into||""}" placeholder="\u7559\u7a7a=\u65e0"></div>
      <div class="fg"><label class="flbl">\u8fdb\u5316\u7b49\u7ea7</label>
        <input id="f_evlv" class="fin" type="number" value="${s.evolve_level||""}"></div>
      <div></div>
    </div>
    <div class="sec" style="margin-top:0">\u79cd\u65cf\u5024</div>
    <div class="stat6" style="margin-bottom:16px">${stI}</div>
    <div class="sec">\u6280\u80fd\u8868 <span style="font-size:10px;color:#555"> \u2014 \u7b49\u7ea7=\u6280\u80fd1,\u6280\u80fd2</span></div>
    <div class="ls-rows" id="lsRows">${lsH}</div>
    <button class="btn btn-back btn-sm" onclick="addLsRow()" style="margin-bottom:14px">+ \u6dfb\u52a0\u7b49\u7ea7</button>
    <div style="display:flex;gap:10px">
      <button class="btn btn-save" onclick="saveMonForm('${id||""}')">&#x1F4BE; \u4fdd\u5b58</button>
      <button class="btn btn-back" onclick="${id?"pickMon('"+id+"')":"clearMonDp()}">\u53d6\u6d88</button>
    </div>`;
}
function lsRow(lv,mv){
  return`<div class="ls-row">
    <input class="fin" type="number" min="1" max="100" value="${lv}" style="width:64px" placeholder="\u7b49\u7ea7">
    <input class="fin" style="flex:1" value="${mv}" placeholder="\u6280\u80fd1,\u6280\u80fd2">
    <button class="btn btn-del btn-sm" onclick="this.parentElement.remove()">&times;</button>
  </div>`;
}
function addLsRow(){
  const d=document.createElement("div");
  d.innerHTML=lsRow("","");
  document.getElementById("lsRows").appendChild(d.firstElementChild);
}
async function saveMonForm(oldId){
  const name=document.getElementById("f_name").value.trim();
  if(!name){alert("\u540d\u79f0\u4e0d\u80fd\u4e3a\u7a7a");return;}
  const ls={};
  document.querySelectorAll(".ls-row").forEach(r=>{
    const ins=r.querySelectorAll("input");
    const lv=ins[0].value.trim(),mv=ins[1].value.trim();
    if(lv&&mv)ls[lv]=mv.split(",").map(s=>s.trim()).filter(Boolean);
  });
  const entry={name,
    type1:document.getElementById("f_t1").value,
    type2:document.getElementById("f_t2").value,
    gender_ratio:document.getElementById("f_gender").value,
    size_info:document.getElementById("f_size").value,
    base:{hp:+document.getElementById("f_hp").value||45,
      atk:+document.getElementById("f_atk").value||50,
      def:+document.getElementById("f_def").value||45,
      sp_atk:+document.getElementById("f_sp_atk").value||50,
      sp_def:+document.getElementById("f_sp_def").value||45,
      spd:+document.getElementById("f_spd").value||50},
    catch_rate:+document.getElementById("f_catch").value||45,
    exp_yield:+document.getElementById("f_exp").value||64,
    growth_rate:document.getElementById("f_gr").value,
    learnset:ls,
    desc:document.getElementById("f_desc").value};
  const evo=document.getElementById("f_evo").value.trim();
  const evlv=parseInt(document.getElementById("f_evlv").value);
  if(evo){entry.evolves_into=evo;entry.evolve_level=evlv||16;}
  if(oldId&&oldId!==name)delete species[oldId];
  species[name]=entry;
  await saveSpecies();
  buildFilters();selMon=name;renderMonList();renderMonDetail(name);
}
async function delMon(id){
  if(!confirm("\u786e\u5b9a\u5220\u9664\u300c"+id+"\u300d\uff1f"))return;
  delete species[id];await saveSpecies();
  buildFilters();selMon=null;renderMonList();clearMonDp();
}
function clearMonDp(){
  document.getElementById("monDp").innerHTML=
    '<div class="empty"><div style="font-size:48px">&#x1F50D;</div><div>\u4ece\u5de6\u4fa7\u9009\u62e9\u7cbe\u7075</div></div>';
}

/* ── Move detail ─────────────────────────────────────────────────────────── */
function pickMov(id){selMov=id;renderMoveList();renderMovDetail(id);}

function renderMovDetail(id){
  const m=moves[id];if(!m)return;
  const catH=m.category?`<span class="${CATCLS[m.category]||"cat-sta"}">${m.category}</span>`:"";
  const eff=EFFECTS.find(e=>e[0]===(m.effect||""));
  const effLabel=eff?eff[1]:m.effect||"\u65e0";
  document.getElementById("moveDp").innerHTML=`
    <div class="actions">
      <button class="btn btn-edit" onclick="openMovEdit('${id}')">&#x270F; \u7f16\u8f91</button>
      <button class="btn btn-del"  onclick="delMov('${id}')">&#x1F5D1; \u5220\u9664</button>
    </div>
    <div style="display:flex;align-items:center;gap:12px;margin-bottom:14px">
      <span style="font-size:22px;font-weight:bold;color:#ffd055">${id}</span>
      ${ttag(m.type,14)} ${catH}
    </div>
    <div style="font-size:12px;color:#8899bb;margin-bottom:16px">${m.description||""}</div>
    <div class="info-grid">
      <div class="icard"><div class="ilbl">\u5a01\u529b</div>
        <div class="ival">${m.power>0?`<b style="color:#f5d76e">${m.power}</b>`:"\u2014"}</div></div>
      <div class="icard"><div class="ilbl">\u547d\u4e2d</div>
        <div class="ival" style="color:#a0d8a0">${m.accuracy||"\u2014"}</div></div>
      <div class="icard"><div class="ilbl">PP</div>
        <div class="ival" style="color:#a0c0e0">${m.max_pp||"\u2014"}</div></div>
      <div class="icard"><div class="ilbl">\u9644\u52a0\u6548\u679c</div>
        <div class="ival">${effLabel}</div></div>
      <div class="icard"><div class="ilbl">\u89e6\u53d1\u6982\u7387</div>
        <div class="ival">${m.effect_chance?m.effect_chance+"%":"\u2014"}</div></div>
    </div>`;
}

/* ── Move form ───────────────────────────────────────────────────────────── */
function openMovNew(){selMov=null;renderMoveList();renderMovForm(null);}
function openMovEdit(id){renderMovForm(id);}

function renderMovForm(id){
  const m=id?moves[id]:{};
  const to=TYPES.filter(t=>t).map(t=>`<option value="${t}"${(m.type||"")==t?" selected":""}>${t}</option>`).join("");
  const co=CATS.map(c=>`<option${(m.category||"")==c?" selected":""}>${c}</option>`).join("");
  const eo=EFFECTS.map(([v,l])=>`<option value="${v}"${(m.effect||"")==v?" selected":""}>${l}</option>`).join("");
  document.getElementById("moveDp").innerHTML=`
    <h2 style="color:#ffd055;margin-bottom:14px;font-size:15px">
      ${id?"\u7f16\u8f91 "+id:"\u65b0\u5efa\u6280\u80fd"}</h2>
    <div class="fgrid">
      <div class="fg"><label class="flbl">\u6280\u80fd\u540d\u79f0 *</label>
        <input id="m_name" class="fin" value="${m.name||id||""}" placeholder="\u6280\u80fd\u540d"></div>
      <div class="fg"><label class="flbl">\u5c5e\u6027 *</label>
        <select id="m_type" class="fin">${to}</select></div>
      <div class="fg"><label class="flbl">\u5206\u7c7b *</label>
        <select id="m_cat" class="fin">${co}</select></div>
      <div class="fg"><label class="flbl">\u5a01\u529b (0=\u53d8\u5316\u62db\u5f0f)</label>
        <input id="m_pow" class="fin" type="number" min="0" max="250" value="${m.power||0}"></div>
      <div class="fg"><label class="flbl">\u547d\u4e2d\u7387 (1-100)</label>
        <input id="m_acc" class="fin" type="number" min="1" max="100" value="${m.accuracy||100}"></div>
      <div class="fg"><label class="flbl">PP</label>
        <input id="m_pp" class="fin" type="number" min="1" max="64" value="${m.max_pp||20}"></div>
      <div class="fg"><label class="flbl">\u9644\u52a0\u6548\u679c</label>
        <select id="m_eff" class="fin">${eo}</select></div>
      <div class="fg"><label class="flbl">\u89e6\u53d1\u6982\u7387 % (\u7559\u7a7a=100%)</label>
        <input id="m_effp" class="fin" type="number" min="0" max="100"
               value="${m.effect_chance||""}" placeholder="\u5982 30 \u8868\u793a 30%"></div>
      <div class="fg full"><label class="flbl">\u6280\u80fd\u8bf4\u660e</label>
        <input id="m_desc" class="fin" value="${(m.description||"").replace(/"/g,"&quot;")}"></div>
    </div>
    <div style="display:flex;gap:10px">
      <button class="btn btn-save" onclick="saveMovForm('${id||""}')">&#x1F4BE; \u4fdd\u5b58</button>
      <button class="btn btn-back" onclick="${id?"pickMov('"+id+"')":"clearMovDp()}">\u53d6\u6d88</button>
    </div>`;
}
async function saveMovForm(oldId){
  const name=document.getElementById("m_name").value.trim();
  if(!name){alert("\u540d\u79f0\u4e0d\u80fd\u4e3a\u7a7a");return;}
  const effp=parseInt(document.getElementById("m_effp").value);
  const entry={name,
    type:document.getElementById("m_type").value,
    category:document.getElementById("m_cat").value,
    power:+document.getElementById("m_pow").value||0,
    accuracy:+document.getElementById("m_acc").value||100,
    max_pp:+document.getElementById("m_pp").value||20,
    effect:document.getElementById("m_eff").value,
    description:document.getElementById("m_desc").value};
  if(effp&&!isNaN(effp))entry.effect_chance=effp;
  if(oldId&&oldId!==name)delete moves[oldId];
  moves[name]=entry;
  await saveMoves();
  selMov=name;renderMoveList();renderMovDetail(name);
}
async function delMov(id){
  if(!confirm("\u786e\u5b9a\u5220\u9664\u6280\u80fd\u300c"+id+"\u300d\uff1f"))return;
  delete moves[id];await saveMoves();
  selMov=null;renderMoveList();clearMovDp();
}
function clearMovDp(){
  document.getElementById("moveDp").innerHTML=
    '<div class="empty"><div style="font-size:48px">\u2728</div><div>\u4ece\u5de6\u4fa7\u9009\u62e9\u6280\u80fd</div></div>';
}

/* ── init ────────────────────────────────────────────────────────────────── */
document.getElementById("srch").addEventListener("input",renderList);
document.getElementById("tflt").addEventListener("change",renderList);
document.getElementById("cflt").addEventListener("change",renderList);
load();
</script>
</body>
</html>"""

# ── HTTP Server ───────────────────────────────────────────────────────────────
class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args): pass

    def _log_err(self, e):
        import traceback
        with open(LOG_FILE, "a", encoding="utf-8") as lf:
            lf.write(f"HANDLER ERROR: {e}\n{traceback.format_exc()}\n")

    def do_GET(self):
        try:
            p = urlparse(self.path).path
            if p in ("/", "/index.html"):
                self._send(200, "text/html", HTML.encode("utf-8"))
            elif p == "/api/species":
                self._send_json(self._load(SPECIES_FILE))
            elif p == "/api/moves":
                self._send_json(self._load(MOVES_FILE))
            else:
                self._send(404, "text/plain", b"Not found")
        except Exception as e:
            self._log_err(e)

    def do_POST(self):
        try:
            p    = urlparse(self.path).path
            body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
            data = json.loads(body)
            if p == "/api/species":
                self._write(SPECIES_FILE, data)
                self._send_json({"ok": True})
            elif p == "/api/moves":
                self._write(MOVES_FILE, data)
                self._send_json({"ok": True})
            else:
                self._send(404, "text/plain", b"Not found")
        except Exception as e:
            self._log_err(e)

    def do_OPTIONS(self):
        self._send(200, "text/plain", b"")

    def _send(self, code, ctype, body):
        self.send_response(code)
        self.send_header("Content-Type", ctype + "; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_json(self, data):
        body = json.dumps(data, ensure_ascii=False, indent=2).encode("utf-8")
        self._send(200, "application/json", body)

    def _load(self, path):
        with open(path, encoding="utf-8") as f:
            return json.load(f)

    def _write(self, path, data):
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

# ── Entry point ───────────────────────────────────────────────────────────────
LOG_FILE = os.path.join(os.path.dirname(os.path.abspath(
    sys.executable if getattr(sys, "frozen", False) else __file__)), "editor.log")

def main():
    import socket, subprocess, traceback
    url = f"http://127.0.0.1:{PORT}"
    # 端口被占用时，杀掉旧进程再启动（避免旧 exe 残留）
    test = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    in_use = test.connect_ex(("127.0.0.1", PORT)) == 0
    test.close()
    if in_use:
        try:
            r = subprocess.run(["netstat", "-ano"], capture_output=True)
            for line in r.stdout.decode("gbk", errors="replace").splitlines():
                if f":{PORT}" in line and "LISTENING" in line:
                    pid = line.strip().split()[-1]
                    subprocess.run(["taskkill", "/F", "/PID", pid], capture_output=True)
        except Exception:
            pass
        import time; time.sleep(0.5)
    try:
        server = HTTPServer(("127.0.0.1", PORT), Handler)
        threading.Timer(0.6, lambda: webbrowser.open(url)).start()
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    except Exception as e:
        with open(LOG_FILE, "a", encoding="utf-8") as lf:
            lf.write(f"ERROR: {e}\n{traceback.format_exc()}")

if __name__ == "__main__":
    main()
