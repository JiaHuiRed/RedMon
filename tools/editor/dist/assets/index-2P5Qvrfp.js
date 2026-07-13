(function(){const e=document.createElement("link").relList;if(e&&e.supports&&e.supports("modulepreload"))return;for(const a of document.querySelectorAll('link[rel="modulepreload"]'))i(a);new MutationObserver(a=>{for(const s of a)if(s.type==="childList")for(const l of s.addedNodes)l.tagName==="LINK"&&l.rel==="modulepreload"&&i(l)}).observe(document,{childList:!0,subtree:!0});function t(a){const s={};return a.integrity&&(s.integrity=a.integrity),a.referrerPolicy&&(s.referrerPolicy=a.referrerPolicy),a.crossOrigin==="use-credentials"?s.credentials="include":a.crossOrigin==="anonymous"?s.credentials="omit":s.credentials="same-origin",s}function i(a){if(a.ep)return;a.ep=!0;const s=t(a);fetch(a.href,s)}})();const H="redmon-editor-theme";function R(){const n=localStorage.getItem(H)||"dark";document.documentElement.setAttribute("data-theme",n)}function V(){const e=document.documentElement.getAttribute("data-theme")==="dark"?"light":"dark";return document.documentElement.setAttribute("data-theme",e),localStorage.setItem(H,e),e}async function I(n,e={},t){return window.__TAURI_INTERNALS__.invoke(n,e,t)}async function z(n){return await I("read_json",{path:n})}async function F(n,e){return await I("write_json",{path:n,data:e})}async function w(n){return await I("read_sprite",{path:n})}async function U(){return await I("open_project")}async function G(n){return await I("load_project",{path:n})}async function Y(){return await I("detect_project_root")}async function J(n){return await I("get_data_paths",{root:n})}const E={空:"#A6A6A6",火:"#F2661A",水:"#337FF2",木:"#33BF40",雷:"#F2D91A",冰:"#99D9F2",格:"#BF401A",毒:"#9933BF",土:"#BF8C33",风:"#8CBFF2",灵:"#E659A6",虫:"#80BF1A",岩:"#B3994D",鬼:"#664DA6",龙:"#4D33E6",暗:"#4D404D",钢:"#B3B3CC",仙:"#F2A6CC",光:"#F2E680"};function W(n){return Object.keys(E).map(t=>`<option value="${t}" ${t===n?"selected":""}>${t}</option>`).join("")}const X=255,Q={hp:"HP",atk:"ATK",def:"DEF",spatk:"SP.ATK",spdef:"SP.DEF",spd:"SPD"},Z={hp:"#FF5959",atk:"#F5AC78",def:"#FAE078",spatk:"#9DB7F5",spdef:"#A7DB8D",spd:"#FA92B2"};function L(n,e,t=X){const i=Math.min(100,e/t*100),a=Z[n]||"#aaa";return`
    <div class="stat-row">
      <span class="stat-label">${Q[n]||n.toUpperCase()}</span>
      <div class="stat-track">
        <div class="stat-fill" style="width:${i}%; background:${a}"></div>
      </div>
      <span class="stat-value">${e}</span>
    </div>
  `}function ee(n){return`
    <div class="stat-row total">
      <span class="stat-label">总计</span>
      <div class="stat-track">
        <div class="stat-fill total" style="width:${Math.min(100,n/720*100)}%"></div>
      </div>
      <span class="stat-value">${n}</span>
    </div>
  `}const te=["慢","中慢","中","中快","快"],ie=["凡","灵","玄","地","神","天"];class ae{constructor(e,t,i,a){var s,l;this.container=e,this.state=t,this.fileKey=i,this.callbacks=a,this.currentId=null,this.data=t.data.species||[],this.filteredData=this.data,this.spritesDir=((l=(s=t.dataPaths)==null?void 0:s.sprites_dir)==null?void 0:l.path)||""}getData(){return this.data}renderList(e){this.data=this.state.data.species||[],this.filteredData=(e?this.data.filter(i=>this._matchFilter(i,e)):this.data).sort((i,a)=>i.id-a.id);const t=document.getElementById("sidebar-list");if(!this.filteredData.length){t.innerHTML='<div class="placeholder">没有精灵数据</div>';return}t.innerHTML=this.filteredData.map(i=>`<div class="sidebar-item ${i.id===this.currentId?"active":""}" data-id="${i.id}">
        <span class="item-id">#${String(i.id).padStart(3,"0")}</span>
        <span class="item-name">${i.name}</span>
        <span class="type-badge type-badge-sm" style="background:${E[i.type1]||"#999"}22; color:${E[i.type1]||"#999"}">${i.type1}</span>
        ${i.type2?`<span class="type-badge type-badge-sm" style="background:${E[i.type2]||"#999"}22; color:${E[i.type2]||"#999"}">${i.type2}</span>`:""}
      </div>`).join(""),t.querySelectorAll(".sidebar-item").forEach(i=>{i.addEventListener("click",()=>this._selectMon(parseInt(i.dataset.id)))})}filterList(e){this.renderList(e)}_matchFilter(e,t){const i=t.toLowerCase();return e.name.toLowerCase().includes(i)||String(e.id).includes(i)||e.type1&&e.type1.includes(i)||e.type2&&e.type2.includes(i)}async _selectMon(e){try{this.currentId=e;const t=this._getSpecies(e);this.callbacks.onStatus(`编辑: ${(t==null?void 0:t.name)||e}`),await this.renderDetail(e),this.renderList()}catch(t){console.error("选择精灵失败:",t),this.callbacks.onStatus(`错误: ${t}`)}}_getSpecies(e){return this.data.find(t=>t.id==e)}_stat(e,t){return e[t]||e[t.replace("atk","_atk").replace("def","_def")]||0}async renderDetail(e){try{await this._doRender(e)}catch(t){console.error("渲染精灵详情失败:",t),this.container.innerHTML=`<div class="placeholder">渲染错误: ${t.message||t}</div>`}}async _doRender(e){var h,f;const t=this._getSpecies(e);if(!t){this.container.innerHTML='<div class="placeholder">未找到精灵</div>';return}console.log("渲染精灵:",e,t==null?void 0:t.name);const i=t.base||{},a=i.hp||0,s=i.atk||0,l=i.def||0,o=this._stat(i,"spatk"),u=this._stat(i,"spdef"),r=i.spd||0,c=a+s+l+o+u+r;this.container.innerHTML=`
      <!-- Top: Sprites + Basic Info -->
      <div class="auto-grid">
        <div class="form-section">
          <div style="display:flex;gap:12px">
            <div class="sprite-preview" id="sprite-preview">
              <div class="sprite-placeholder">加载中...</div>
            </div>
            <div class="sprite-preview" id="sprite-back-preview">
              <div class="sprite-placeholder">背面</div>
            </div>
          </div>
        </div>

        <div class="form-section">
          <div class="form-section-title">基本信息</div>
          <div class="form-grid">
            <div class="form-group">
              <label>ID</label>
              <input type="number" id="field-id" value="${t.id}" min="1" />
            </div>
            <div class="form-group">
              <label>名称</label>
              <input type="text" id="field-name" value="${t.name}" />
            </div>
            <div class="form-group">
              <label>属性 1</label>
              <select id="field-type1">${this._typeOptions(t.type1)}</select>
            </div>
            <div class="form-group">
              <label>属性 2</label>
              <select id="field-type2"><option value="">无</option>${this._typeOptions(t.type2)}</select>
            </div>
            <div class="form-group">
              <label>品阶</label>
              <select id="field-tier">${ie.map(v=>`<option value="${v}" ${t.tier===v?"selected":""}>${v}</option>`).join("")}</select>
            </div>
            <div class="form-group">
              <label>捕获率</label>
              <input type="number" id="field-catch" value="${t.catch_rate||45}" min="0" max="255" />
            </div>
            <div class="form-group">
              <label>经验值</label>
              <input type="number" id="field-exp" value="${t.exp_yield||100}" min="0" />
            </div>
            <div class="form-group">
              <label>成长率</label>
              <select id="field-growth">${te.map(v=>`<option value="${v}" ${t.growth_rate===v?"selected":""}>${v}</option>`).join("")}</select>
            </div>
            <div class="form-group">
              <label>性别比例</label>
              <input type="text" id="field-gender" value="${t.gender_ratio||""}" placeholder="如 1:1" />
            </div>
            <div class="form-group">
              <label>身高 (m)</label>
              <input type="text" id="field-height" value="${t.height||""}" />
            </div>
            <div class="form-group">
              <label>体重 (kg)</label>
              <input type="text" id="field-weight" value="${t.weight||""}" />
            </div>
            <div class="form-group">
              <label>特性 1</label>
              <select id="field-ability1">${this._abilityOptions(((h=t.abilities)==null?void 0:h[0])||"")}</select>
            </div>
            <div class="form-group">
              <label>特性 2</label>
              <select id="field-ability2">${this._abilityOptions(((f=t.abilities)==null?void 0:f[1])||"")}</select>
            </div>
          </div>
        </div>
      </div>

      <!-- Stats -->
      <div class="form-section">
        <div class="form-section-title">种族值 <span style="font-weight:400;color:var(--text-muted);font-size:12px">Lv50: ${Math.floor(c*.5+60)} | Lv100: ${c+60}</span></div>
        <div class="form-grid" style="margin-bottom:12px">
          <div class="form-group"><label>HP</label><input type="number" id="stat-hp" value="${a}" min="0" max="255" /></div>
          <div class="form-group"><label>ATK</label><input type="number" id="stat-atk" value="${s}" min="0" max="255" /></div>
          <div class="form-group"><label>DEF</label><input type="number" id="stat-def" value="${l}" min="0" max="255" /></div>
          <div class="form-group"><label>SP.ATK</label><input type="number" id="stat-spatk" value="${o}" min="0" max="255" /></div>
          <div class="form-group"><label>SP.DEF</label><input type="number" id="stat-spdef" value="${u}" min="0" max="255" /></div>
          <div class="form-group"><label>SPD</label><input type="number" id="stat-spd" value="${r}" min="0" max="255" /></div>
        </div>
        <div class="stat-group">
          ${L("hp",a)}
          ${L("atk",s)}
          ${L("def",l)}
          ${L("spatk",o)}
          ${L("spdef",u)}
          ${L("spd",r)}
          ${ee(c)}
        </div>
      </div>

      <!-- Encounters -->
      <div class="form-section">
        <div class="section-header">
          <span class="form-section-title">遭遇地</span>
          <div>
            <button class="btn btn-sm" id="btn-add-enc">+ 添加地点</button>
          </div>
        </div>
        <div id="enc-container">
          ${this._renderEncounters(t)}
        </div>
      </div>

      <!-- Evolution -->
      <div class="form-section">
        <div class="section-header">
          <span class="form-section-title">进化链</span>
          <div>
            <button class="btn btn-sm" id="btn-add-evo">+ 添加进化</button>
          </div>
        </div>
        <div id="evo-container">
          ${this._renderEvoChain(t)}
        </div>
      </div>

      <!-- Learnset -->
      <div class="form-section">
        <div class="section-header">
          <span class="form-section-title">学习技能</span>
          <div>
            <button class="btn btn-sm" id="btn-add-learn">+ 添加技能</button>
          </div>
        </div>
        <table class="list-table" id="learnset-table">
          <thead>
            <tr>
              <th style="width:50px">等级</th>
              <th>技能名称</th>
              <th style="width:40px"></th>
            </tr>
          </thead>
          <tbody>
            ${this._renderLearnset(t)}
          </tbody>
        </table>
      </div>

      <!-- Description -->
      <div class="form-section">
        <div class="form-section-title">图鉴描述</div>
        <div class="form-grid">
          <div class="form-group full-width">
            <textarea id="field-desc" rows="3">${t.desc||""}</textarea>
          </div>
        </div>
      </div>

      <!-- Type Matchup -->
      <div class="form-section">
        <div class="form-section-title">属性克制</div>
        <div id="matchup-container">
          ${this._renderMatchup(t)}
        </div>
      </div>
    `,this._bindDetailEvents(t),this._loadSprite(t.id)}onAdd(){const t={id:this.data.reduce((i,a)=>Math.max(i,a.id||0),0)+1,name:"新精灵",type1:"木",type2:"",base:{hp:50,atk:50,def:50,spatk:50,spdef:50,spd:50},tier:"凡",catch_rate:45,exp_yield:100,growth_rate:"中",desc:"",height:"",weight:"",gender_ratio:"",evolutions:[],learnset:[],abilities:[]};this.data.push(t),this.callbacks.onModified(this.fileKey),this._selectMon(t.id)}onDelete(){if(!this.currentId)return;const e=this._getSpecies(this.currentId);if(!e)return;const t=e.name||`#${e.id}`;if(!confirm(`确认删除「${t}」？此操作不可撤销。`))return;const i=this.data.findIndex(a=>a.id==this.currentId);i!==-1&&this.data.splice(i,1),this.currentId=null,this.callbacks.onModified(this.fileKey),this.container.innerHTML='<div class="placeholder">精灵已删除</div>',this.renderList()}_getAbilitiesList(){return(this.state.data.abilities||[]).map(t=>t.name).filter(Boolean)}_abilityOptions(e){return`<option value="">无</option>${this._getAbilitiesList().map(i=>`<option value="${i}" ${i===e?"selected":""}>${i}</option>`).join("")}`}_typeOptions(e){return Object.keys(E).map(t=>`<option value="${t}" ${t===e?"selected":""}>${t}</option>`).join("")}_renderEvoChain(e){if(!e.evolutions||e.evolutions.length===0)return'<div style="color:var(--text-muted);padding:8px">无进化</div>';const t=this.data,i=a=>{if(a.id){const s=t.find(l=>l.id==a.id);return s?s.name:`#${a.id}`}return a.into?a.into:"?"};return`<div class="evo-chain">
      <div class="evo-node">
        <span class="evo-name">${e.name}</span>
      </div>
      ${e.evolutions.map(a=>`
        <span class="evo-arrow">→</span>
        <div class="evo-node" data-evo-id="${a.id||""}">
          <span class="evo-name">${i(a)}</span>
          <span class="evo-condition">${a.level?`Lv.${a.level}`:a.condition||""}</span>
        </div>
      `).join("")}
    </div>`}_renderLearnset(e){return!e.learnset||e.learnset.length===0?'<tr><td colspan="3" style="text-align:center;color:var(--text-muted)">无技能</td></tr>':[...e.learnset].sort((i,a)=>(i.level||999)-(a.level||999)).map((i,a)=>`<tr>
        <td><input type="number" value="${i.level||0}" class="learn-level" data-idx="${a}" style="width:50px" /></td>
        <td><input type="text" value="${i.name||""}" class="learn-name" data-idx="${a}" style="width:100%" /></td>
        <td><button class="remove-btn learn-remove" data-idx="${a}">✕</button></td>
      </tr>`).join("")}_renderEncounters(e){return!e.encounters||e.encounters.length===0?'<div style="color:var(--text-muted);padding:8px">无遭遇数据</div>':e.encounters.map((t,i)=>`<div class="enc-item" data-enc-idx="${i}">
        <input type="text" class="enc-location" data-idx="${i}" value="${t.location||""}" placeholder="地点" />
        <input type="number" class="enc-rate" data-idx="${i}" value="${t.rate||0}" min="0" max="100" style="width:60px" placeholder="%" />
        <button class="remove-btn enc-remove" data-idx="${i}">✕</button>
      </div>`).join("")}_renderMatchup(e){const t=Object.keys(E),i=e.type1,a=e.type2,s={空:{岩:.6,钢:.6,鬼:0},火:{木:1.5,冰:1.5,虫:1.5,钢:1.5,火:.6,水:.6,岩:.6,龙:.6},水:{火:1.5,土:1.5,岩:1.5,水:.6,木:.6,龙:.6},木:{水:1.5,土:1.5,岩:1.5,火:.6,木:.6,毒:.6,风:.6,虫:.6,龙:.6,钢:.6},雷:{水:1.5,风:1.5,雷:.6,木:.6,龙:.6,土:0},冰:{木:1.5,土:1.5,风:1.5,龙:1.5,火:.6,水:.6,冰:.6,钢:.6},格:{空:1.5,冰:1.5,岩:1.5,暗:1.5,钢:1.5,毒:.6,风:.6,灵:.6,虫:.6,仙:.6,鬼:0},毒:{木:1.5,仙:1.5,毒:.6,土:.6,岩:.6,鬼:.6,钢:0},土:{火:1.5,雷:1.5,毒:1.5,岩:1.5,钢:1.5,木:.6,虫:.6,风:0},风:{木:1.5,格:1.5,虫:1.5,雷:.6,岩:.6,钢:.6},灵:{格:1.5,毒:1.5,灵:.6,钢:.6},虫:{木:1.5,灵:1.5,暗:1.5,仙:1.5,火:.6,格:.6,风:.6,鬼:.6,钢:.6},岩:{火:1.5,冰:1.5,风:1.5,虫:1.5,格:.6,土:.6,钢:.6},鬼:{灵:1.5,鬼:1.5,暗:.6,空:0},龙:{龙:1.5,钢:.6,仙:0},暗:{灵:1.5,鬼:1.5,光:1.5,格:.6,暗:.6,仙:.6},钢:{冰:1.5,岩:1.5,仙:1.5,火:.6,水:.6,雷:.6,钢:.6},仙:{格:1.5,龙:1.5,暗:1.5,火:.6,毒:.6,钢:.6},光:{鬼:1.5,虫:1.5,冰:1.5,暗:1.5,火:.6,钢:.6,光:.6,水:.6,木:0}};return`<table class="matchup-table">
      <thead><tr><th>攻击属性</th><th>${i}${a?" / "+a:""}</th></tr></thead>
      <tbody>
      ${t.filter(l=>l).map(l=>{var f,v;const o=((f=s[l])==null?void 0:f[i])??1,u=a?o*(((v=s[l])==null?void 0:v[a])??1):o,r=u===0?"免":u<1?`×${u}`:u>1?`×${u}`:"—",c=u===0?"immune":u<1?"resist":u>1?"weak":"normal",h=E[l];return`<tr class="${c}">
          <td><span class="type-badge type-badge-sm" style="background:${h||"#999"}">${l}</span></td>
          <td class="matchup-val">${r}</td>
        </tr>`}).join("")}
      </tbody>
    </table>`}async _loadSprite(e){const t=document.getElementById("sprite-preview");if(!t)return;const i=`${this.spritesDir}/${String(e).padStart(3,"0")}.png`;try{const s=await w(i);t.innerHTML=`
        <img src="${s}" alt="Sprite #${e}" />
        <div class="sprite-controls">
          <button class="btn btn-sm" id="btn-toggle-shiny" title="闪光预览">✨</button>
        </div>
      `;const l=document.getElementById("btn-toggle-shiny");if(l){const o=i.replace(".png","_shiny.png");l.addEventListener("click",async()=>{try{const u=await w(o),r=t.querySelector("img");r&&(r.src=u)}catch{this.callbacks.onStatus("无闪光精灵图")}})}}catch{t.innerHTML='<div class="sprite-placeholder">无精灵图</div>',console.warn("[species] front sprite load failed for",e)}const a=document.getElementById("sprite-back-preview");if(a){const s=`${this.spritesDir}/${String(e).padStart(3,"0")}_back.png`;try{const l=await w(s);a.innerHTML=`<img src="${l}" alt="Back #${e}" />`}catch{a.innerHTML='<div class="sprite-placeholder">无背面图</div>'}}}_bindDetailEvents(e){const t=(r,c,h)=>{const f=document.getElementById(r);f&&f.addEventListener("change",()=>{e[c]=h?h(f.value):f.value,this.callbacks.onModified(this.fileKey)})},i=(r,c)=>t(r,c,h=>h===""?0:parseInt(h)||0),a=(r,c)=>t(r,c,h=>h);i("field-id","id"),a("field-name","name"),t("field-type1","type1"),t("field-type2","type2"),t("field-tier","tier"),i("field-catch","catch_rate"),i("field-exp","exp_yield"),t("field-growth","growth_rate"),a("field-gender","gender_ratio"),a("field-height","height"),a("field-weight","weight"),a("field-desc","desc"),t("field-ability1","abilities",r=>{var f;const c=r||"",h=((f=e.abilities)==null?void 0:f[1])||"";if(!r&&!h){e.abilities=[];return}e.abilities=[c,h].filter(Boolean)}),t("field-ability2","abilities",r=>{var f;const c=((f=e.abilities)==null?void 0:f[0])||"",h=r||"";if(!c&&!r){e.abilities=[];return}e.abilities=[c,h].filter(Boolean)});const s=(r,c)=>{const h=document.getElementById(r);h&&h.addEventListener("change",()=>{e.base||(e.base={}),e.base[c]=parseInt(h.value)||0,this.callbacks.onModified(this.fileKey),this.renderDetail(e.id)})};s("stat-hp","hp"),s("stat-atk","atk"),s("stat-def","def"),s("stat-spatk","spatk"),s("stat-spdef","spdef"),s("stat-spd","spd");const l=document.getElementById("btn-add-evo");l&&l.addEventListener("click",()=>{e.evolutions||(e.evolutions=[]),e.evolutions.push({id:0,level:16,condition:""}),this.callbacks.onModified(this.fileKey),this.renderDetail(e.id)}),document.querySelectorAll("[data-evo-id]").forEach(r=>{const c=parseInt(r.dataset.evoId);r.addEventListener("click",()=>{var f;const h=(f=e.evolutions)==null?void 0:f.find(v=>v.id===c);if(h){const v=prompt("进化目标 ID:",h.id);v&&(h.id=parseInt(v)||0,this.callbacks.onModified(this.fileKey),this.renderDetail(e.id))}})});const o=document.getElementById("btn-add-learn");o&&o.addEventListener("click",()=>{e.learnset||(e.learnset=[]),e.learnset.push({level:1,name:""}),this.callbacks.onModified(this.fileKey),this.renderDetail(e.id)}),document.querySelectorAll(".learn-remove").forEach(r=>{r.addEventListener("click",()=>{const c=parseInt(r.dataset.idx);e.learnset&&(e.learnset.splice(c,1),this.callbacks.onModified(this.fileKey),this.renderDetail(e.id))})}),document.querySelectorAll(".learn-level").forEach(r=>{r.addEventListener("change",()=>{const c=parseInt(r.dataset.idx);e.learnset&&e.learnset[c]&&(e.learnset[c].level=parseInt(r.value)||0,this.callbacks.onModified(this.fileKey))})}),document.querySelectorAll(".learn-name").forEach(r=>{r.addEventListener("change",()=>{const c=parseInt(r.dataset.idx);e.learnset&&e.learnset[c]&&(e.learnset[c].name=r.value,this.callbacks.onModified(this.fileKey))})});const u=document.getElementById("btn-add-enc");u&&u.addEventListener("click",()=>{e.encounters||(e.encounters=[]),e.encounters.push({location:"",rate:0}),this.callbacks.onModified(this.fileKey),this.renderDetail(e.id)}),document.querySelectorAll(".enc-remove").forEach(r=>{r.addEventListener("click",()=>{const c=parseInt(r.dataset.idx);e.encounters&&(e.encounters.splice(c,1),this.callbacks.onModified(this.fileKey),this.renderDetail(e.id))})}),document.querySelectorAll(".enc-location").forEach(r=>{r.addEventListener("change",()=>{const c=parseInt(r.dataset.idx);e.encounters&&e.encounters[c]&&(e.encounters[c].location=r.value,this.callbacks.onModified(this.fileKey))})}),document.querySelectorAll(".enc-rate").forEach(r=>{r.addEventListener("change",()=>{const c=parseInt(r.dataset.idx);e.encounters&&e.encounters[c]&&(e.encounters[c].rate=parseInt(r.value)||0,this.callbacks.onModified(this.fileKey))})})}}const se=["物理","特殊","变化"],ne={"":"-- 无效果 --",inflict_burn:"烧伤",inflict_freeze:"冰冻",inflict_paralysis:"麻痹",inflict_poison:"中毒",inflict_sleep:"睡眠",heal_self:"回复HP",high_crit:"易暴击",lower_atk:"降低物攻",lower_acc:"降低命中",lower_spd:"降低速度",raise_def:"提升物防",raise_sp_atk:"提升特攻",raise_sp_def:"提升特防",raise_spd:"提升速度",recoil:"反伤",priority:"先制"},C=new Set(["inflict_burn","inflict_freeze","inflict_paralysis","inflict_poison","inflict_sleep"]),P=new Set(["heal_self","recoil"]);class le{constructor(e,t,i,a){this.container=e,this.state=t,this.fileKey=i,this.callbacks=a,this.currentId=null,this.data=t.data.moves||[]}getData(){return this.data}renderList(e){this.data=this.state.data.moves||[];const t=e?this.data.filter(a=>this._match(a,e)):this.data,i=document.getElementById("sidebar-list");if(!t.length){i.innerHTML='<div class="placeholder">无技能数据</div>';return}i.innerHTML=t.map(a=>`<div class="sidebar-item ${a.id===this.currentId?"active":""}" data-move="${a.id}">
        <span class="item-name">${a.name}</span>
        <span style="font-size:11px;color:var(--text-muted)">${a.type||""} ${a.category||""}</span>
        <span style="font-size:11px;color:var(--text-muted);font-family:var(--font-mono)">${a.power||"-"}/${a.accuracy||"-"}</span>
      </div>`).join(""),i.querySelectorAll("[data-move]").forEach(a=>{a.addEventListener("click",()=>this._select(parseInt(a.dataset.move)))})}filterList(e){this.renderList(e)}_match(e,t){const i=t.toLowerCase();return e.name.toLowerCase().includes(i)||e.type&&e.type.includes(t)}_select(e){this.currentId=e,this.callbacks.onStatus(`编辑技能: ${e}`);const t=this.data.find(i=>i.id===e);t&&this.renderDetail(t),this.renderList()}renderDetail(e){var a,s;this.container.innerHTML=`
      <div class="form-section">
        <div class="form-section-title">技能信息</div>
        <div class="form-grid">
          <div class="form-group">
            <label>ID</label>
            <input type="text" id="mv-id" value="${e.id}" />
          </div>
          <div class="form-group">
            <label>名称</label>
            <input type="text" id="mv-name" value="${e.name}" />
          </div>
          <div class="form-group">
            <label>属性</label>
            <select id="mv-type">${W(e.type)}</select>
          </div>
          <div class="form-group">
            <label>分类</label>
            <select id="mv-category">${se.map(l=>`<option value="${l}" ${e.category===l?"selected":""}>${l}</option>`).join("")}</select>
          </div>
          <div class="form-group">
            <label>威力</label>
            <input type="number" id="mv-power" value="${e.power||0}" min="0" />
          </div>
          <div class="form-group">
            <label>命中率</label>
            <input type="number" id="mv-accuracy" value="${e.accuracy||0}" min="0" max="100" />
          </div>
          <div class="form-group">
            <label>PP</label>
            <input type="number" id="mv-pp" value="${e.pp||0}" min="0" />
          </div>
          <div class="form-group">
            <label>优先级</label>
            <input type="number" id="mv-priority" value="${e.priority||0}" />
          </div>
          <div class="form-group">
            <label>效果类型</label>
            <select id="mv-effect">${Object.entries(ne).map(([l,o])=>`<option value="${l}" ${e.effect===l?"selected":""}>${o}</option>`).join("")}</select>
          </div>
          <div class="form-group" id="mv-effect-chance-group" style="display:${C.has(e.effect)?"block":"none"}">
            <label>概率%</label>
            <input type="number" id="mv-effect-chance" value="${e.effect_chance||0}" min="0" max="100" />
          </div>
          <div class="form-group" id="mv-effect-value-group" style="display:${P.has(e.effect)?"block":"none"}">
            <label>数值%</label>
            <input type="number" id="mv-effect-value" value="${e.effect_value||0}" min="0" />
          </div>
          <div class="form-group full-width">
            <label>效果描述</label>
            <textarea id="mv-desc" rows="3">${e.desc||""}</textarea>
          </div>
        </div>
      </div>
    `;const t=(l,o)=>{var u;(u=document.getElementById(l))==null||u.addEventListener("change",()=>{const r=document.getElementById(l).value;o==="power"||o==="accuracy"||o==="pp"||o==="priority"?e[o]=parseInt(r)||0:e[o]=r,this.callbacks.onModified(this.fileKey)})};t("mv-id","id"),t("mv-name","name"),t("mv-type","type"),t("mv-category","category"),t("mv-power","power"),t("mv-accuracy","accuracy"),t("mv-pp","pp"),t("mv-priority","priority"),t("mv-desc","desc");const i=document.getElementById("mv-effect");i&&i.addEventListener("change",(function(){e.effect=this.value;const l=document.getElementById("mv-effect-chance-group"),o=document.getElementById("mv-effect-value-group");l&&(l.style.display=C.has(this.value)?"block":"none"),o&&(o.style.display=P.has(this.value)?"block":"none"),this.callbacks.onModified(this.fileKey)}).bind(e)),(a=document.getElementById("mv-effect-chance"))==null||a.addEventListener("change",(function(){e.effect_chance=parseInt(this.value)||0,this.callbacks.onModified(this.fileKey)}).bind(e)),(s=document.getElementById("mv-effect-value"))==null||s.addEventListener("change",(function(){e.effect_value=parseInt(this.value)||0,this.callbacks.onModified(this.fileKey)}).bind(e))}onAdd(){const e=this.data.reduce((t,i)=>Math.max(t,parseInt(i.id)||0),0);this.data.push({id:String(e+1),name:"新技能",type:"木",category:"物理",power:60,accuracy:100,pp:20,priority:0,desc:""}),this.callbacks.onModified(this.fileKey),this._select(parseInt(e+1))}onDelete(){if(!this.currentId)return;const e=this.data.find(t=>t.id===this.currentId);!e||!confirm(`确认删除技能「${e.name}」？`)||(this.data=this.data.filter(t=>t.id!==this.currentId),this.state.data.moves=this.data,this.currentId=null,this.callbacks.onModified(this.fileKey),this.container.innerHTML='<div class="placeholder">技能已删除</div>',this.renderList())}}const de=["回复","技能机","捕捉","滋补","进化"],re=[{value:"",label:"-- 无 --"},{value:"hp",label:"HP"},{value:"atk",label:"ATK"},{value:"def",label:"DEF"},{value:"sp_atk",label:"SP.ATK"},{value:"sp_def",label:"SP.DEF"},{value:"spd",label:"SPD"}];class ce{constructor(e,t,i,a){var s,l;this.container=e,this.state=t,this.fileKey=i,this.callbacks=a,this.currentId=null,this.data=t.data.items||[],this.iconsDir=((l=(s=t.dataPaths)==null?void 0:s.items_dir)==null?void 0:l.path)||""}getData(){return this.data}renderList(e){this.data=this.state.data.items||[];const t=e?this.data.filter(a=>this._match(a,e)):this.data,i=document.getElementById("sidebar-list");if(!t.length){i.innerHTML='<div class="placeholder">无道具数据</div>';return}i.innerHTML=t.map(a=>`<div class="sidebar-item ${a.id===this.currentId?"active":""}" data-id="${a.id}">
        <span class="item-name">${a.name}</span>
        <span style="font-size:11px;color:var(--text-muted)">${a.category||""}</span>
      </div>`).join(""),i.querySelectorAll("[data-id]").forEach(a=>{a.addEventListener("click",()=>this._select(parseInt(a.dataset.id)))})}filterList(e){this.renderList(e)}_match(e,t){const i=t.toLowerCase();return e.name.toLowerCase().includes(i)||(e.category||"").includes(t)}_select(e){this.currentId=e,this.callbacks.onStatus(`编辑道具: ${e}`);const t=this.data.find(i=>i.id===e);t&&this.renderDetail(t),this.renderList()}renderDetail(e){var i,a;this.container.innerHTML=`
      <div class="auto-grid">
        <div class="form-section">
          <div class="form-section-title">道具信息</div>
          <div class="form-grid">
            <div class="form-group">
              <label>ID</label><input type="text" id="it-id" value="${e.id}" />
            </div>
            <div class="form-group">
              <label>名称</label><input type="text" id="it-name" value="${e.name}" />
            </div>
            <div class="form-group">
              <label>分类</label>
              <select id="it-category">${de.map(s=>`<option value="${s}" ${e.category===s?"selected":""}>${s}</option>`).join("")}</select>
            </div>
            <div class="form-group">
              <label>价格</label><input type="number" id="it-price" value="${e.price||0}" min="0" />
            </div>
            <div class="form-group">
              <label>效果</label><input type="text" id="it-effect" value="${e.effect||""}" />
            </div>
            <div class="form-group" id="it-train-stat-group" style="display:${e.category==="滋补"?"block":"none"}">
              <label>努力值属性</label>
              <select id="it-train-stat">${re.map(s=>`<option value="${s.value}" ${e.train_stat===s.value?"selected":""}>${s.label}</option>`).join("")}</select>
            </div>
            <div class="form-group" id="it-train-amount-group" style="display:${e.category==="滋补"?"block":"none"}">
              <label>努力值增量</label>
              <input type="number" id="it-train-amount" value="${e.train_amount||0}" min="0" />
            </div>
            <div class="form-group full-width">
              <label>描述</label>
              <textarea id="it-desc" rows="3">${e.desc||""}</textarea>
            </div>
          </div>
        </div>
        <div class="form-section">
          <div class="sprite-preview" id="item-icon-preview">
            <div class="sprite-placeholder">无图标</div>
          </div>
        </div>
      </div>
    `;const t=(s,l,o)=>{var u;(u=document.getElementById(s))==null||u.addEventListener("change",()=>{const r=document.getElementById(s).value;e[l]=o?parseInt(r)||0:r,this.callbacks.onModified(this.fileKey)})};t("it-id","id"),t("it-name","name"),t("it-category","category"),t("it-price","price",!0),t("it-effect","effect"),t("it-desc","desc"),t("it-train-stat","train_stat"),(i=document.getElementById("it-train-amount"))==null||i.addEventListener("change",()=>{e.train_amount=parseInt(document.getElementById("it-train-amount").value)||0,this.callbacks.onModified(this.fileKey)}),(a=document.getElementById("it-category"))==null||a.addEventListener("change",function(){const s=this.value==="滋补",l=document.getElementById("it-train-stat-group"),o=document.getElementById("it-train-amount-group");l&&(l.style.display=s?"block":"none"),o&&(o.style.display=s?"block":"none")}),this._loadItemIcon(e)}async _loadItemIcon(e){const t=document.getElementById("item-icon-preview");if(!t)return;const i=e.name;if(!i){t.innerHTML='<div class="sprite-placeholder">无图标</div>';return}const a=`${this.iconsDir}/${i}.png`;console.debug("[items] loading icon from:",a);try{const s=await w(a);t.innerHTML=`<img src="${s}" alt="${i}" />`}catch(s){console.warn("[items] icon load error:",s),t.innerHTML='<div class="sprite-placeholder">无图标</div>'}}onAdd(){const e=this.data.reduce((t,i)=>Math.max(t,parseInt(i.id)||0),0);this.data.push({id:e+1,name:"新道具",category:"回复",price:0,effect:"",desc:""}),this.callbacks.onModified(this.fileKey),this._select(e+1)}onDelete(){if(!this.currentId)return;const e=this.data.find(i=>i.id===this.currentId);if(!e||!confirm(`确认删除道具「${e.name}」？`))return;const t=this.data.findIndex(i=>i.id===this.currentId);t!==-1&&this.data.splice(t,1),this.currentId=null,this.callbacks.onModified(this.fileKey),this.container.innerHTML='<div class="placeholder">道具已删除</div>',this.renderList()}}const oe={"":"-- 无战斗效果 --",immune_status:"免疫异常状态",immune_type:"免疫特定属性",weather:"天气效果",on_switch_in:"出场时触发",stat_boost_passive:"被动数值加成",stat_boost_low_hp:"低血量强化",damage_reduce:"伤害减免",damage_boost:"伤害加成",contact_punish:"接触反伤",other:"其他效果"};class pe{constructor(e,t,i,a){this.container=e,this.state=t,this.fileKey=i,this.callbacks=a,this.currentId=null,this.data=t.data.abilities||[]}getData(){return this.data}renderList(e){this.data=this.state.data.abilities||[];const t=e?this.data.filter(a=>this._match(a,e)):this.data,i=document.getElementById("sidebar-list");if(!t.length){i.innerHTML='<div class="placeholder">无特性数据</div>';return}i.innerHTML=t.map(a=>`<div class="sidebar-item ${a.id===this.currentId?"active":""}" data-id="${a.id}">
        <span class="item-name">${a.name}</span>
      </div>`).join(""),i.querySelectorAll("[data-id]").forEach(a=>{a.addEventListener("click",()=>this._select(parseInt(a.dataset.id)))})}filterList(e){this.renderList(e)}_match(e,t){return e.name.toLowerCase().includes(t.toLowerCase())}_select(e){this.currentId=e,this.callbacks.onStatus(`编辑特性: ${e}`);const t=this.data.find(i=>i.id===e);t&&this.renderDetail(t),this.renderList()}renderDetail(e){this.container.innerHTML=`
      <div class="form-section">
        <div class="form-section-title">特性信息</div>
        <div class="form-grid">
          <div class="form-group">
            <label>ID</label><input type="text" id="ab-id" value="${e.id}" />
          </div>
          <div class="form-group">
            <label>名称</label><input type="text" id="ab-name" value="${e.name}" />
          </div>
          <div class="form-group">
            <label>效果类型</label>
            <select id="ab-effect">${Object.entries(oe).map(([i,a])=>`<option value="${i}" ${e.effect===i?"selected":""}>${a}</option>`).join("")}</select>
          </div>
          <div class="form-group full-width">
            <label>效果描述</label>
            <textarea id="ab-desc" rows="4">${e.desc||""}</textarea>
          </div>
        </div>
      </div>
    `;const t=(i,a)=>{var s;(s=document.getElementById(i))==null||s.addEventListener("change",()=>{e[a]=document.getElementById(i).value,this.callbacks.onModified(this.fileKey)})};t("ab-id","id"),t("ab-name","name"),t("ab-effect","effect"),t("ab-desc","desc")}onAdd(){const e=this.data.reduce((t,i)=>Math.max(t,parseInt(i.id)||0),0);this.data.push({id:e+1,name:"新特性",desc:""}),this.callbacks.onModified(this.fileKey),this._select(e+1)}onDelete(){if(!this.currentId)return;const e=this.data.find(i=>i.id===this.currentId);if(!e||!confirm(`确认删除特性「${e.name}」？`))return;const t=this.data.findIndex(i=>i.id===this.currentId);t!==-1&&this.data.splice(t,1),this.currentId=null,this.callbacks.onModified(this.fileKey),this.container.innerHTML='<div class="placeholder">特性已删除</div>',this.renderList()}}const ue=["教授","劲敌","普通NPC","家人","村民","道馆主","四天王","反派","训练师"],he=["普通训练师","精英训练师","道馆学徒","道馆主","四天王","冠军","反派干部","反派首领","劲敌","路人","商人","研究员","武者","渔夫","虫师"],fe=["0 - 路人杂兵 (IV=0)","1 - 普通训练师 (IV=8)","2 - 精英/道馆杂兵 (IV=16)","3 - 道馆主/首领 (IV=25)","4 - 四天王/冠军/黑风堂主 (IV=31)"];class ve{constructor(e,t,i,a){var s,l;this.container=e,this.state=t,this.fileKey=i,this.callbacks=a,this.currentId=null,this.data=t.data.npcs||[],this.spritesDir=((l=(s=t.dataPaths)==null?void 0:s.npc_sprites_dir)==null?void 0:l.path)||""}getData(){return this.data}renderList(e){this.data=this.state.data.npcs||[];const t=e?this.data.filter(a=>this._match(a,e)):this.data,i=document.getElementById("sidebar-list");if(!t.length){i.innerHTML='<div class="placeholder">无角色数据</div>';return}i.innerHTML=t.map(a=>`<div class="sidebar-item ${a.id===this.currentId?"active":""}" data-id="${a.id}">
        <span class="item-name">${a.name}</span>
        <span style="font-size:11px;color:var(--text-muted)">${a.trainer_type||""}</span>
      </div>`).join(""),i.querySelectorAll("[data-id]").forEach(a=>{a.addEventListener("click",()=>this._select(a.dataset.id))})}filterList(e){this.renderList(e)}_match(e,t){const i=t.toLowerCase();return e.name.toLowerCase().includes(i)||(e.trainer_type||"").toLowerCase().includes(i)}async _select(e){this.currentId=e,this.callbacks.onStatus(`编辑角色: ${e}`);const t=this.data.find(i=>i.id===e);t&&await this.renderDetail(t),this.renderList()}async renderDetail(e){var o,u,r,c,h,f,v,A,B,j,K;const t=e.trainer||{},i=(t.team||[]).map((d,p)=>`<tr>
        <td><input type="text" value="${d.species||""}" class="tr-team-species" data-idx="${p}" style="width:80px" /></td>
        <td><input type="number" value="${d.level||1}" class="tr-team-level" data-idx="${p}" style="width:50px" min="1" /></td>
        <td><input type="text" value="${(d.moves||[]).join(",")}" class="tr-team-moves" data-idx="${p}" style="width:120px" placeholder="用逗号分隔" /></td>
        <td><input type="text" value="${d.item||""}" class="tr-team-item" data-idx="${p}" style="width:60px" /></td>
        <td><button class="remove-btn tr-team-remove" data-idx="${p}">✕</button></td>
      </tr>`).join("")||'<tr><td colspan="5" style="text-align:center;color:var(--text-muted)">无队伍</td></tr>',a=(e.party||[]).map((d,p)=>`<tr>
        <td><input type="text" value="${d.id||""}" class="np-party-id" data-idx="${p}" style="width:60px" /></td>
        <td><input type="number" value="${d.level||1}" class="np-party-level" data-idx="${p}" style="width:50px" min="1" /></td>
        <td><button class="remove-btn np-party-remove" data-idx="${p}">✕</button></td>
      </tr>`).join("")||'<tr><td colspan="3" style="text-align:center;color:var(--text-muted)">无队伍</td></tr>';this.container.innerHTML=`
      <div class="auto-grid">
        <div class="form-section">
          <div class="sprite-preview" id="npc-sprite-preview">
            <div class="sprite-placeholder">加载中...</div>
          </div>
        </div>
        <div class="form-section">
          <div class="form-section-title">角色信息</div>
          <div class="form-grid">
            <div class="form-group">
              <label>ID</label><input type="text" id="np-id" value="${e.id}" />
            </div>
            <div class="form-group">
              <label>名称</label><input type="text" id="np-name" value="${e.name}" />
            </div>
            <div class="form-group">
              <label>称号</label><input type="text" id="np-title" value="${e.title||""}" placeholder="如「青木村的守护者」" />
            </div>
            <div class="form-group">
              <label>训练师类型</label>
              <select id="np-type">${ue.map(d=>`<option value="${d}" ${e.trainer_type===d?"selected":""}>${d}</option>`).join("")}</select>
            </div>
            <div class="form-group">
              <label>性别</label>
              <select id="np-gender">
                <option value="">未设置</option>
                <option value="男" ${e.gender==="男"?"selected":""}>男</option>
                <option value="女" ${e.gender==="女"?"selected":""}>女</option>
              </select>
            </div>
            <div class="form-group full-width">
              <label>描述</label>
              <textarea id="np-desc" rows="2">${e.desc||""}</textarea>
            </div>
            <div class="form-group full-width">
              <label>对话</label>
              <textarea id="np-dialog" rows="3">${e.dialog||""}</textarea>
            </div>
          </div>
        </div>
      </div>
      <details class="form-section" ${t.trainer_id?"open":""}>
        <summary class="form-section-title">训练师数据</summary>
        <div class="form-grid">
          <div class="form-group">
            <label>训练师ID</label><input type="text" id="tr-id" value="${t.trainer_id||""}" />
          </div>
          <div class="form-group">
            <label>职业</label>
            <select id="tr-class">${he.map(d=>`<option value="${d}" ${t.class===d?"selected":""}>${d}</option>`).join("")}</select>
          </div>
          <div class="form-group">
            <label>奖金</label><input type="number" id="tr-reward" value="${t.reward||0}" />
          </div>
          <div class="form-group">
            <label>IV等级</label>
            <select id="tr-iv-tier">${fe.map((d,p)=>`<option value="${p}" ${(t.iv_tier??-1)===p?"selected":""}>${d}</option>`).join("")}</select>
          </div>
          <div class="form-group full-width">
            <label>战前对话</label>
            <textarea id="tr-dialog-before" rows="2">${t.dialog_before||""}</textarea>
          </div>
          <div class="form-group full-width">
            <label>战后对话（胜利）</label>
            <textarea id="tr-dialog-win" rows="2">${t.dialog_win||""}</textarea>
          </div>
          <div class="form-group full-width">
            <label>战后对话（失败）</label>
            <textarea id="tr-dialog-lose" rows="2">${t.dialog_lose||""}</textarea>
          </div>
          <div class="form-group full-width">
            <label>玩家败北对话</label>
            <textarea id="tr-dialog-player-lose" rows="2">${t.dialog_player_lose||""}</textarea>
          </div>
          <div class="form-group full-width">
            <label>战后对话</label>
            <textarea id="tr-dialog-after" rows="2">${t.dialog_after||""}</textarea>
          </div>
        </div>
        <div class="section-header" style="margin-top:12px">
          <span class="form-section-title">训练师队伍</span>
          <button class="btn btn-sm" id="tr-add-team">+ 添加</button>
        </div>
        <table class="list-table">
          <thead><tr><th style="width:90px">精灵</th><th style="width:60px">等级</th><th style="width:130px">技能</th><th style="width:70px">携带道具</th><th style="width:40px"></th></tr></thead>
          <tbody>${i}</tbody>
        </table>
      </details>
      <div class="form-section">
        <div class="section-header">
          <span class="form-section-title">NPC队伍（旧格式，建议用训练师队伍）</span>
          <button class="btn btn-sm" id="np-add-party">+ 添加</button>
        </div>
        <table class="list-table">
          <thead><tr><th style="width:70px">精灵ID</th><th style="width:60px">等级</th><th style="width:40px"></th></tr></thead>
          <tbody>${a}</tbody>
        </table>
      </div>
    `,(o=document.getElementById("np-id"))==null||o.addEventListener("change",d=>{e.id=d.target.value,this.callbacks.onModified(this.fileKey)}),(u=document.getElementById("np-name"))==null||u.addEventListener("change",d=>{e.name=d.target.value,this.callbacks.onModified(this.fileKey)}),(r=document.getElementById("np-title"))==null||r.addEventListener("change",d=>{e.title=d.target.value,this.callbacks.onModified(this.fileKey)}),(c=document.getElementById("np-type"))==null||c.addEventListener("change",d=>{e.trainer_type=d.target.value,this.callbacks.onModified(this.fileKey)}),(h=document.getElementById("np-gender"))==null||h.addEventListener("change",d=>{e.gender=d.target.value,this.callbacks.onModified(this.fileKey)}),(f=document.getElementById("np-desc"))==null||f.addEventListener("change",d=>{e.desc=d.target.value,this.callbacks.onModified(this.fileKey)}),(v=document.getElementById("np-dialog"))==null||v.addEventListener("change",d=>{e.dialog=d.target.value,this.callbacks.onModified(this.fileKey)});const s=()=>(e.trainer||(e.trainer={}),e.trainer),l=(d,p)=>{var g;(g=document.getElementById(d))==null||g.addEventListener("change",S=>{const N=s();N[p]=S.target.value,this.callbacks.onModified(this.fileKey)})};l("tr-id","trainer_id"),l("tr-class","class"),l("tr-dialog-before","dialog_before"),l("tr-dialog-win","dialog_win"),l("tr-dialog-lose","dialog_lose"),l("tr-dialog-player-lose","dialog_player_lose"),l("tr-dialog-after","dialog_after"),(A=document.getElementById("tr-reward"))==null||A.addEventListener("change",d=>{const p=s();p.reward=parseInt(d.target.value)||0,this.callbacks.onModified(this.fileKey)}),(B=document.getElementById("tr-iv-tier"))==null||B.addEventListener("change",d=>{const p=s();p.iv_tier=parseInt(d.target.value),this.callbacks.onModified(this.fileKey)}),(j=document.getElementById("tr-add-team"))==null||j.addEventListener("click",()=>{const d=s();d.team||(d.team=[]),d.team.push({species:"",level:5,moves:[],item:""}),this.callbacks.onModified(this.fileKey),this.renderDetail(e)}),document.querySelectorAll(".tr-team-species, .tr-team-level, .tr-team-moves, .tr-team-item").forEach(d=>{d.addEventListener("change",()=>{const p=s(),g=parseInt(d.dataset.idx);p.team[g]&&(d.classList.contains("tr-team-species")?p.team[g].species=d.value:d.classList.contains("tr-team-level")?p.team[g].level=parseInt(d.value)||1:d.classList.contains("tr-team-moves")?p.team[g].moves=d.value?d.value.split(",").map(S=>S.trim()).filter(Boolean):[]:d.classList.contains("tr-team-item")&&(p.team[g].item=d.value),this.callbacks.onModified(this.fileKey))})}),document.querySelectorAll(".tr-team-remove").forEach(d=>{d.addEventListener("click",()=>{const p=s(),g=parseInt(d.dataset.idx);p.team&&(p.team.splice(g,1),this.callbacks.onModified(this.fileKey),this.renderDetail(e))})}),(K=document.getElementById("np-add-party"))==null||K.addEventListener("click",()=>{e.party||(e.party=[]),e.party.push({id:"",level:5}),this.callbacks.onModified(this.fileKey),this.renderDetail(e)}),document.querySelectorAll(".np-party-id").forEach(d=>{d.addEventListener("change",()=>{const p=parseInt(d.dataset.idx);e.party[p]&&(e.party[p].id=d.value,this.callbacks.onModified(this.fileKey))})}),document.querySelectorAll(".np-party-level").forEach(d=>{d.addEventListener("change",()=>{const p=parseInt(d.dataset.idx);e.party[p]&&(e.party[p].level=parseInt(d.value)||1,this.callbacks.onModified(this.fileKey))})}),document.querySelectorAll(".np-party-remove").forEach(d=>{d.addEventListener("click",()=>{const p=parseInt(d.dataset.idx);e.party&&(e.party.splice(p,1),this.callbacks.onModified(this.fileKey),this.renderDetail(e))})}),this._loadNpcSprite(e)}async _loadNpcSprite(e){const t=document.getElementById("npc-sprite-preview");if(!t)return;const i=e.sprite_front;if(!i){t.innerHTML='<div class="sprite-placeholder">无精灵图</div>';return}const a=`${this.spritesDir}/${i}`;try{const s=await w(a);t.innerHTML=`<img src="${s}" alt="${e.name}" />`}catch{t.innerHTML='<div class="sprite-placeholder">无精灵图</div>'}}onAdd(){const e={id:`npc_${Date.now()}`,name:"新角色",trainer_type:"普通NPC",title:"",gender:"",desc:"",dialog:"",sprite_front:"",party:[]};this.data.push(e),this.callbacks.onModified(this.fileKey),this._select(e.id)}onDelete(){if(!this.currentId)return;const e=this.data.find(i=>i.id===this.currentId);if(!e||!confirm(`确认删除角色「${e.name}」？`))return;const t=this.data.findIndex(i=>i.id===this.currentId);t!==-1&&this.data.splice(t,1),this.currentId=null,this.callbacks.onModified(this.fileKey),this.container.innerHTML='<div class="placeholder">角色已删除</div>',this.renderList()}}class me{constructor(e,t,i,a){this.container=e,this.state=t,this.fileKey=i,this.callbacks=a,this.currentId=null,this.data=[]}getData(){return this.data}renderList(e){const t=this.state.data.dialogs||{};this.data=t;const i=Object.keys(t),a=e?i.filter(l=>l.includes(e)):i,s=document.getElementById("sidebar-list");if(!a.length){s.innerHTML='<div class="placeholder">无剧情文本数据</div>';return}s.innerHTML=a.map(l=>`<div class="sidebar-item ${l===this.currentId?"active":""}" data-key="${l}">
        <span class="item-name">${l}</span>
      </div>`).join(""),s.querySelectorAll("[data-key]").forEach(l=>{l.addEventListener("click",()=>this._select(l.dataset.key))})}filterList(e){this.renderList(e)}_select(e){this.currentId=e,this.callbacks.onStatus(`编辑剧情: ${e}`),this.renderDetail(e),this.renderList()}renderDetail(e){var i;const t=this.data[e]||"";this.container.innerHTML=`
      <div class="form-section">
        <div class="form-section-title">${e}</div>
        <div class="form-grid">
          <div class="form-group full-width">
            <label>内容</label>
            <textarea id="dl-content" rows="20" style="font-family:var(--font-mono);font-size:13px;line-height:1.6">${typeof t=="object"?JSON.stringify(t,null,2):t}</textarea>
          </div>
        </div>
      </div>
    `,(i=document.getElementById("dl-content"))==null||i.addEventListener("change",a=>{const s=a.target.value;try{this.data[e]=JSON.parse(s)}catch{this.data[e]=s}this.callbacks.onModified(this.fileKey)})}}const be=["野外","城市","室内","道馆","洞穴","水域","特殊"];class ye{constructor(e,t,i,a){this.container=e,this.state=t,this.fileKey=i,this.callbacks=a,this.currentId=null,this.data=t.data.maps||[]}getData(){return this.data}renderList(e){this.data=this.state.data.maps||[];const t=e?this.data.filter(a=>this._match(a,e)):this.data,i=document.getElementById("sidebar-list");if(!t.length){i.innerHTML='<div class="placeholder">无地图数据</div>';return}i.innerHTML=t.map(a=>`<div class="sidebar-item ${a.id===this.currentId?"active":""}" data-id="${a.id}">
        <span class="item-name">${a.name}</span>
        <span style="font-size:11px;color:var(--text-muted)">${a.type||""}</span>
      </div>`).join(""),i.querySelectorAll("[data-id]").forEach(a=>{a.addEventListener("click",()=>this._select(parseInt(a.dataset.id)))})}filterList(e){this.renderList(e)}_match(e,t){const i=t.toLowerCase();return e.name.toLowerCase().includes(i)||(e.type||"").toLowerCase().includes(i)}_select(e){this.currentId=e,this.callbacks.onStatus(`编辑地图: ${e}`);const t=this.data.find(i=>i.id===e);t&&this.renderDetail(t),this.renderList()}renderDetail(e){var i;this.container.innerHTML=`
      <div class="form-section">
        <div class="form-section-title">地图信息</div>
        <div class="form-grid">
          <div class="form-group">
            <label>ID</label><input type="number" id="mp-id" value="${e.id}" />
          </div>
          <div class="form-group">
            <label>名称</label><input type="text" id="mp-name" value="${e.name}" />
          </div>
          <div class="form-group">
            <label>类型</label>
            <select id="mp-type">${be.map(a=>`<option value="${a}" ${e.type===a?"selected":""}>${a}</option>`).join("")}</select>
          </div>
          <div class="form-group">
            <label>场景文件</label><input type="text" id="mp-scene" value="${e.scene||""}" />
          </div>
          <div class="form-group full-width">
            <label>描述</label>
            <textarea id="mp-desc" rows="3">${e.desc||""}</textarea>
          </div>
          <div class="form-group">
            <label>道馆</label>
            <input type="text" id="mp-gym" value="${e.gym||""}" placeholder="如「翠竹道馆」" />
          </div>
          <div class="form-group full-width">
            <label>关联NPC（逗号分隔）</label>
            <textarea id="mp-npcs" rows="2">${(e.npcs||[]).join(", ")}</textarea>
          </div>
        </div>
      </div>
    `;const t=(a,s)=>{var l;(l=document.getElementById(a))==null||l.addEventListener("change",()=>{e[s]=document.getElementById(a).value,this.callbacks.onModified(this.fileKey)})};t("mp-id","id"),t("mp-name","name"),t("mp-type","type"),t("mp-scene","scene"),t("mp-desc","desc"),t("mp-gym","gym"),(i=document.getElementById("mp-npcs"))==null||i.addEventListener("change",a=>{e.npcs=a.target.value.split(",").map(s=>s.trim()).filter(Boolean),this.callbacks.onModified(this.fileKey)})}onAdd(){const e=this.data.reduce((t,i)=>Math.max(t,parseInt(i.id)||0),0);this.data.push({id:e+1,name:"新地图",type:"野外",scene:"",npcs:[]}),this.callbacks.onModified(this.fileKey),this._select(e+1)}onDelete(){if(!this.currentId)return;const e=this.data.find(i=>i.id===this.currentId);if(!e||!confirm(`确认删除地图「${e.name}」？`))return;const t=this.data.findIndex(i=>i.id===this.currentId);t!==-1&&this.data.splice(t,1),this.currentId=null,this.callbacks.onModified(this.fileKey),this.container.innerHTML='<div class="placeholder">地图已删除</div>',this.renderList()}}const m={projectRoot:null,dataPaths:null,data:{},modified:{}},_={};let x="species";const D={species:{key:"species",label:"精灵图鉴",file:"species",TabClass:ae},moves:{key:"moves",label:"技能库",file:"moves",TabClass:le},items:{key:"items",label:"道具",file:"items",TabClass:ce},abilities:{key:"abilities",label:"特性",file:"abilities",TabClass:pe},npcs:{key:"npcs",label:"角色",file:"npcs",TabClass:ve},dialogs:{key:"dialogs",label:"剧情文本",file:"dialogs",TabClass:me},maps:{key:"maps",label:"地图",file:"maps",TabClass:ye}},b=n=>document.getElementById(n),y={projectPath:b("project-path"),sidebarList:b("sidebar-list"),searchInput:b("search-input"),statusText:b("status-text"),sidebarActions:b("sidebar-actions"),btnAdd:b("btn-add-entry"),btnDelete:b("btn-delete-entry")};function ge(n){x=n,document.querySelectorAll(".tab-btn").forEach(t=>{t.classList.toggle("active",t.dataset.tab===n)}),document.querySelectorAll(".tab-content").forEach(t=>{t.classList.toggle("active",t.id===`tab-${n}`)});const e=_[n];e&&(y.searchInput.value="",e.renderList()),k()}function k(){const n=_[x];if(!n||!y.sidebarActions)return;const e=n.onAdd||n.onDelete;y.sidebarActions.style.display=e?"flex":"none",y.btnDelete.style.display=n.currentId&&n.onDelete?"block":"none"}async function $e(){try{$("正在打开项目...");const n=await U();await T(n.root)}catch(n){$(`错误: ${n}`)}}async function T(n){var e;m.projectRoot=n,y.projectPath.textContent=n,y.projectPath.title=n,localStorage.setItem("redmon-last-project",n),m.dataPaths=await J(n),await Ee();for(const[t,i]of Object.entries(D)){const a=document.getElementById(`tab-${t}`),s=new i.TabClass(a,m,t,{onSave:(l,o)=>_e(l,o),onStatus:$,onModified:l=>{m.modified[l]=!0,M()}});_[t]=s}(e=_[x])==null||e.renderList(),$(`已加载项目: ${n}`),M(),k()}async function Ee(){for(const[n,e]of Object.entries(D)){const t=m.dataPaths[e.file];if(!t||!t.exists){m.data[e.file]=n==="dialogs"?{}:[];continue}try{let i=await z(t.path);if(n==="dialogs")m.data[e.file]=i;else if(n==="maps"){const a=i.maps||{};m.data[e.file]=Object.entries(a).map(([s,l])=>(l.name||(l.name=s),l))}else m.data[e.file]=Object.entries(i).map(([a,s],l)=>(s.name||(s.name=a),s.id===void 0&&(s.id=l+1),n==="species"&&s.learnset&&!Array.isArray(s.learnset)&&(s.learnset=Object.entries(s.learnset).map(([o,u])=>({level:parseInt(o)||1,name:u}))),s));m.modified[e.file]=!1}catch(i){console.warn(`加载 ${e.file}.json 失败:`,i),m.data[e.file]=n==="dialogs"?{}:[]}}}function O(n,e){if(n==="dialogs")return e;if(n==="maps"){const a={};for(const s of e)a[s.name]=s;return{_comment:"地图列表——编辑器地图tab管理，关联NPC/遇敌/传送点",maps:a}}const t=n==="npcs"?"id":"name",i={};for(const a of e)i[a[t]]=a;return i}async function _e(n,e){const t=m.dataPaths[n];if(t)try{await F(t.path,O(n,e)),m.modified[n]=!1,M(),$(`已保存 ${n}.json`)}catch(i){$(`保存失败: ${i}`)}}async function q(){for(const[n,e]of Object.entries(D)){const t=m.dataPaths[e.file];if(t&&t.exists&&m.modified[e.file]){const i=_[n];if(i&&i.getData)try{const a=i.getData();await F(t.path,O(e.file,a)),m.modified[e.file]=!1}catch(a){$(`保存 ${e.file}.json 失败: ${a}`);return}}}m.modified={},M(),$("全部已保存")}function M(){const n=Object.values(m.modified).some(t=>t),e=b("btn-save-all");e&&(e.style.opacity=n?"1":"0.4")}y.searchInput.addEventListener("input",n=>{const e=_[x];e&&e.filterList&&e.filterList(n.target.value)});function $(n){y.statusText.textContent=n}document.addEventListener("keydown",n=>{(n.ctrlKey||n.metaKey)&&n.key==="s"&&(n.preventDefault(),q())});async function Ie(){var e,t,i;R(),document.querySelectorAll(".tab-btn").forEach(a=>{a.addEventListener("click",()=>ge(a.dataset.tab))}),b("btn-open-project").addEventListener("click",$e),b("btn-save-all").addEventListener("click",q),b("btn-theme").addEventListener("click",()=>{const a=V();b("btn-theme").textContent=a==="dark"?"🌙":"☀️"}),(e=y.btnAdd)==null||e.addEventListener("click",()=>{const a=_[x];a&&a.onAdd&&(a.onAdd(),k())}),(t=y.btnDelete)==null||t.addEventListener("click",()=>{const a=_[x];a&&a.onDelete&&(a.onDelete(),k())}),(i=y.sidebarList)==null||i.addEventListener("click",()=>setTimeout(k,0));try{const a=await Y();await T(a.root);return}catch(a){console.warn("自动检测项目失败:",a)}const n=localStorage.getItem("redmon-last-project");if(n)try{await G(n),await T(n);return}catch(a){console.warn("自动加载失败:",a)}$("就绪 — 点击 📂 打开项目")}Ie();
