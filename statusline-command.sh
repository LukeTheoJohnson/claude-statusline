#!/usr/bin/env bash
# Single-file Claude Code status line. One node process: it reads the payload
# from stdin, resolves the git branch in-process (no second spawn, no shell
# git line), and renders everything native from the JSON.
exec node -e '
const cp=require("child_process");
let d="";
process.stdin.on("data",c=>d+=c);
process.stdin.on("end",()=>{
  let p={}; try{p=JSON.parse(d)}catch{}
  const R="\x1b[0m";
  const c=(s,col)=>"\x1b["+col+"m"+s+R;
  const SEP=c("|","0;90");
  const parts=[];

  // branch — resolved in-process via execFileSync (no shell, no extra spawn;
  // main red = commit guard, amber otherwise)
  const cwd=(p?.workspace?.current_dir||p?.cwd||"").replace(/\\/g,"/");
  let branch="";
  if(cwd){
    try{
      branch=cp.execFileSync("git",["-C",cwd,"--no-optional-locks","symbolic-ref","--short","HEAD"],
        {stdio:["ignore","pipe","ignore"]}).toString().trim();
    }catch{}
  }
  if(branch){
    const col=(branch==="main"||branch==="master")?"0;31":"0;33";
    parts.push(c(branch,col));
  }

  // model.display_name direct
  const model=p?.model?.display_name||"";
  if(model) parts.push(c(model,"0;35"));

  // reasoning effort
  const eff=p?.effort?.level;
  if(eff) parts.push(c("E:"+eff,"0;36"));

  // lines changed from cost
  const add=p?.cost?.total_lines_added||0, del=p?.cost?.total_lines_removed||0;
  if(add||del) parts.push(c("+"+add,"0;32")+"/"+c("-"+del,"0;31"));

  // session cost native
  const cost=p?.cost?.total_cost_usd||0;
  if(cost>0) parts.push(c("$"+cost.toFixed(2),"0;32"));

  // bar with optional pacing marker
  const bar=(pct,pace,w=8)=>{
    const fill=Math.round(pct/100*w);
    const mark=pace!=null?Math.min(w-1,Math.floor(pace/100*w)):-1;
    let s="";
    for(let i=0;i<w;i++){
      if(i===mark) s+="\x1b[1;37m│\x1b[0m";   // white pacing marker
      else s+=i<fill?"█":"░";
    }
    return s;
  };
  const tcol=pct=> pct<45?"0;32":pct<70?"0;33":"0;31"; // green/amber/red (rate limits, no pacing)
  const ccol=pct=> pct<15?"0;32":pct<50?"0;33":"0;31"; // context: conservative — amber at 15%, red at 50%

  // burn-aware colour for rate limits: they reset on a rolling clock, so what
  // matters is usage vs. how far through the window you are (the pacing marker),
  // not the raw %. Project current burn to the reset — under the pace line lands
  // with headroom (green), well ahead of it exhausts early (red). Falls back to
  // raw thresholds when there is no reset time to pace against.
  const bcol=(pct,pace)=>{
    if(pace==null) return tcol(pct);            // no pacing info → raw thresholds
    if(pct<15) return "0;32";                   // negligible usage → green (no early-window noise)
    if(pct>=90) return "0;31";                  // near the cap: red regardless of pace
    const proj=pct*100/Math.max(pace,8);        // projected % at reset (clamp early window)
    if(proj<90)  return pct<80?"0;32":"0;33";   // headroom → green (amber if abs usage high)
    if(proj<110) return "0;33";                 // lands near the cap → amber
    return pct<25?"0;33":"0;31";                // projected to blow it → red (amber if abs still low)
  };

  // context: percentage is already relative to the real window size, so it
  // reads correctly on 200k and 1M models. Show remaining tokens from the
  // actual context_window_size rather than assuming 200k.
  const cxw=p?.context_window||{};
  const ctx=Math.floor(cxw.used_percentage||0);
  let ctxSeg=c("ctx:"+ctx+"%",ccol(ctx))+bar(ctx,null,6);
  const size=cxw.context_window_size||0, used=cxw.total_input_tokens||0;
  if(size){
    const freeK=Math.max(0,Math.round((size-used)/1000));
    ctxSeg+=c(" "+freeK+"k",ccol(ctx));
  }
  parts.push(ctxSeg);

  // 200k overflow flag (fixed threshold, meaningful waypoint on 1M models)
  if(p?.exceeds_200k_tokens) parts.push(c("⚠200k","0;31"));

  // reset-time + pacing helpers
  const now=Date.now()/1000;
  const rt=ts=>{
    if(!ts)return""; let s=ts-now; if(s<0)return"";
    const day=Math.floor(s/86400);
    if(day>=1){ const h=Math.floor(s%86400/3600); return h?(day+"d"+h+"h"):(day+"d"); }
    const h=Math.floor(s/3600),m=Math.floor(s%3600/60);
    return h?(h+"h"+m+"m"):(m+"m");
  };
  const pace=(ts,win)=>{ if(!ts)return null; const f=(now-(ts-win))/win; return Math.max(0,Math.min(100,f*100)); };

  // rate limit segment (Pro/Max only; each window may be independently absent)
  const limit=(rl,label,win)=>{
    if(!rl||rl.used_percentage==null)return;
    const u=Math.floor(rl.used_percentage);
    const pc=pace(rl.resets_at,win);
    let s=c(label+":"+u+"%",bcol(u,pc))+bar(u,pc);
    const t=rt(rl.resets_at); if(t) s+=c("→"+t,"0;90");
    parts.push(s);
  };
  limit(p?.rate_limits?.five_hour,"5h",18000);    // 5h  = 18000s
  limit(p?.rate_limits?.seven_day,"7d",604800);   // 7d  = 604800s

  process.stdout.write(parts.join(" "+SEP+" "));
});
' 2>/dev/null
