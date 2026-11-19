param([string]$InputFolder,[string]$OutputFile)
$ErrorActionPreference='Stop'
Write-Host "`nDiscord Data Package - Single HTML Viewer" -ForegroundColor Cyan
if(-not $InputFolder){$InputFolder=(Read-Host 'Enter UNZIPPED Discord package folder').Trim().Trim('"').Trim("'")}
if(-not (Test-Path -LiteralPath $InputFolder -PathType Container)){throw "Folder not found: $InputFolder"}
$root=(Resolve-Path -LiteralPath $InputFolder).Path
if(-not $OutputFile){$OutputFile=Join-Path (Split-Path $root -Parent) 'Discord_Complete_Viewer.html'}
$OutputFile=[IO.Path]::GetFullPath($OutputFile)
$script:issues=New-Object 'System.Collections.Generic.List[object]'
$script:entries=New-Object 'System.Collections.Generic.List[object]'
$script:media=New-Object 'System.Collections.Generic.List[object]'
$script:other=New-Object 'System.Collections.Generic.List[object]'
$script:channels=@{}
$script:users=@{}
$script:owner='Account owner'
$script:ownerId=''
function Prop($o,[string[]]$names){if($null -eq $o){return $null};foreach($n in $names){if($o -is [System.Collections.IDictionary]){if($o.Contains($n)){return $o[$n]}}elseif($null -ne $o.PSObject.Properties[$n]){return $o.PSObject.Properties[$n].Value}};return $null}
function Txt($o){if($null -eq $o){return ''};if($o -is [string]){return $o};if($o -is [ValueType]){return [string]$o};return (ConvertTo-Json -InputObject $o -Depth 60 -Compress)}
function Html($o){return [Net.WebUtility]::HtmlEncode([string]$o)}
function Js($o){$s=ConvertTo-Json -InputObject $o -Depth 80 -Compress;return $s.Replace('<','\u003c').Replace('>','\u003e').Replace('&','\u0026').Replace([string][char]0x2028,'\u2028').Replace([string][char]0x2029,'\u2029')}
function Time($o){$s=Txt $o;if(-not $s){return ''};try{if($s -match '^\d{13}$'){return [DateTimeOffset]::FromUnixTimeMilliseconds([long]$s).UtcDateTime.ToString('yyyy-MM-dd HH:mm:ss')+' UTC'};if($s -match '^\d{10}$'){return [DateTimeOffset]::FromUnixTimeSeconds([long]$s).UtcDateTime.ToString('yyyy-MM-dd HH:mm:ss')+' UTC'};return [DateTimeOffset]::Parse($s.Trim('"'),[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss')+' UTC'}catch{return $s}}
function ReadJson($f){
 try{$raw=[IO.File]::ReadAllText($f,[Text.Encoding]::UTF8);if(-not $raw.Trim()){return $null};return (ConvertFrom-Json -InputObject $raw -ErrorAction Stop)}catch{
  # Discord Activity reporting/analytics often uses NDJSON (one JSON object per line).
  $rows=New-Object 'System.Collections.Generic.List[object]';$lineNo=0;$bad=0
  try{foreach($line in [IO.File]::ReadLines($f)){ $lineNo++;if(-not $line.Trim()){continue};try{$rows.Add((ConvertFrom-Json -InputObject $line -ErrorAction Stop))}catch{$bad++;if($bad -le 3){$script:issues.Add([pscustomobject]@{File=$f;Error="Line $lineNo : $($_.Exception.Message)"})}}};if($rows.Count -gt 0){return ,($rows.ToArray())}}catch{}
  $script:issues.Add([pscustomobject]@{File=$f;Error='Could not parse JSON or newline-delimited JSON'});return $null
 }
}
function Rel($p){return $p.Substring($root.Length).TrimStart('\','/')}
function Person($value){
 if($null -eq $value){return ''};if($value -is [string] -or $value -is [ValueType]){$id=[string]$value;if($script:users.ContainsKey($id)){return $script:users[$id]};if($id -eq $script:ownerId){return $script:owner};return $id}
 $id=Txt (Prop $value @('id','user_id'));$name=Txt (Prop $value @('global_name','username','name','display_name','tag'));if($name){if($id){$script:users[$id]=$name};return $name};if($id){return (Person $id)};return ''
}
function Url($s){try{$u=[uri]([string]$s);if($u.IsAbsoluteUri -and $u.Scheme -in @('https','http')){return $u.AbsoluteUri}}catch{};return ''}
function AddMedia($value,$channel,$message,$source){
 foreach($v in @($value)){
  if($null -eq $v){continue};$u='';$name='';$mime='';$local=''
  if($v -is [string]){$u=$v}else{$u=Txt (Prop $v @('url','proxy_url','attachment_url','href'));$name=Txt (Prop $v @('filename','name','title'));$mime=Txt (Prop $v @('content_type','mime_type','type'));$local=Txt (Prop $v @('path','local_path'))}
  if(-not $name -and $u){try{$name=[IO.Path]::GetFileName(([uri]$u).AbsolutePath)}catch{$name=$u}}
  if(-not $u -and -not $local){continue}
  $kind='file';if($mime -match '^image/' -or $name -match '(?i)\.(png|jpe?g|gif|webp|bmp|svg)$' -or $u -match '(?i)\.(png|jpe?g|gif|webp)(\?|$)'){$kind='image'}elseif($mime -match '^video/' -or $name -match '(?i)\.(mp4|webm|mov|m4v)$'){$kind='video'}elseif($mime -match '^audio/' -or $name -match '(?i)\.(mp3|ogg|wav|m4a)$'){$kind='audio'}
  $script:media.Add([pscustomobject]@{kind=$kind;name=$name;url=(Url $u);local=$local;channel=$channel;message=$message;source=$source})
 }
}
$files=@(Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {$_.FullName -ne $OutputFile})
$json=@($files | Where-Object {$_.Extension -eq '.json'})
Write-Host "Found $($files.Count) files ($($json.Count) JSON files)." -ForegroundColor Cyan
# First pass: identify account and channels before rendering messages.
$index=0
foreach($f in $json){
 $index++;Write-Progress -Id 1 -Activity 'Discord package analysis' -Status "Reading account and channel metadata: $index / $($json.Count)" -PercentComplete ([int](20*$index/[Math]::Max(1,$json.Count)))
 $rel=Rel $f.FullName
 if($rel -match '^(?i)Account[\\/]'){
  $obj=ReadJson $f.FullName;if($null -eq $obj){continue}
  $id=Txt (Prop $obj @('id','user_id'));$name=Txt (Prop $obj @('global_name','username','name'))
  if($id -and -not $script:ownerId){$script:ownerId=$id};if($name -and $script:owner -eq 'Account owner'){$script:owner=$name}
  $script:other.Add([pscustomobject]@{section='Account';source=$rel;data=$obj})
 }elseif($f.Name -ieq 'channel.json' -and $rel -match '^(?i)Messages[\\/]'){
  $obj=ReadJson $f.FullName;if($null -eq $obj){continue};$folder=$f.DirectoryName
  $id=Txt (Prop $obj @('id','channel_id'));$name=Txt (Prop $obj @('name','channel_name'));$type=Txt (Prop $obj @('type'))
  $people=New-Object 'System.Collections.Generic.List[string]'
  foreach($p in @((Prop $obj @('recipients','recipient_ids','participants')))){$pn=Person $p;if($pn){$people.Add($pn)}}
  $script:channels[$folder]=[pscustomobject]@{id=$id;name=$name;type=$type;people=@($people);raw=$obj}
 }
}
if($script:ownerId){$script:users[$script:ownerId]=$script:owner}
$index=0
foreach($f in $json){
 $index++;Write-Progress -Id 1 -Activity 'Discord package analysis' -Status "Parsing files: $index / $($json.Count) - $($f.Name)" -PercentComplete ([int](20+65*$index/[Math]::Max(1,$json.Count)))
 $rel=Rel $f.FullName
 if($rel -match '^(?i)Account[\\/]' -or $f.Name -ieq 'channel.json'){continue}
 $obj=ReadJson $f.FullName;if($null -eq $obj){continue}
 if($rel -match '^(?i)Messages[\\/]'){
  $ch=$script:channels[$f.DirectoryName];$folder=Split-Path $f.DirectoryName -Leaf
  $cid=$folder;$cname=$folder;$ctype='';$people=@()
  if($ch){if($ch.id){$cid=$ch.id};if($ch.name){$cname=$ch.name};$ctype=$ch.type;$people=@($ch.people)}
  if((-not $ch -or -not $ch.name) -and $people.Count){$cname=$people -join ', '}
  if($cname -eq $folder -and $people.Count){$cname='DM: '+($people -join ', ')}
  if($cname -eq $folder -and $ctype -match 'DM'){ $cname='DM '+$cid }
  $items=@();if($obj -is [array]){$items=@($obj)}elseif($null -ne (Prop $obj @('messages'))){$items=@(Prop $obj @('messages'))}elseif($null -ne (Prop $obj @('id','ID'))){$items=@($obj)}
  foreach($m in $items){if($null -eq $m){continue}
   $id=Txt (Prop $m @('ID','id','message_id'));$time=Time (Prop $m @('Timestamp','timestamp','created_at'));$content=Txt (Prop $m @('Contents','contents','content'))
   $author=Person (Prop $m @('author','author_id','user_id'));if(-not $author){$author=$script:owner}
   $atts=Prop $m @('Attachments','attachments');AddMedia $atts $cname $id $rel
   $script:entries.Add([pscustomobject]@{id=$id;timestamp=$time;sender=$author;channel=$cname;channelId=$cid;channelType=$ctype;participants=($people -join ', ');content=$content;source=$rel;attachments=@($atts)})
  }
 }else{
  $section=($rel -split '[\\/]')[0];$script:other.Add([pscustomobject]@{section=$section;source=$rel;data=$obj})
 }
}
# Collect non-JSON files as inventory only. Embed small local media for a truly portable single-file viewer.
$embedded=@{};$limit=15MB;$totalLimit=75MB;$total=0
foreach($f in $files){
 if($f.Extension -match '(?i)^\.(png|jpg|jpeg|gif|webp|mp4|webm|mp3|wav|ogg|pdf)$' -and $f.Length -le $limit -and ($total+$f.Length) -le $totalLimit){
  try{$mime=switch($f.Extension.ToLower()){'.png'{'image/png'} '.jpg'{'image/jpeg'} '.jpeg'{'image/jpeg'} '.gif'{'image/gif'} '.webp'{'image/webp'} '.mp4'{'video/mp4'} '.webm'{'video/webm'} '.mp3'{'audio/mpeg'} '.wav'{'audio/wav'} '.ogg'{'audio/ogg'} '.pdf'{'application/pdf'}};$embedded[(Rel $f.FullName)]='data:'+$mime+';base64,'+[Convert]::ToBase64String([IO.File]::ReadAllBytes($f.FullName));$total+=$f.Length}catch{}
 }
}
$inventory=@($files | ForEach-Object {[pscustomobject]@{path=(Rel $_.FullName);bytes=$_.Length}})
$payload=[ordered]@{owner=$script:owner;ownerId=$script:ownerId;messages=@($script:entries.ToArray());media=@($script:media.ToArray());other=@($script:other.ToArray());channels=@($script:channels.Values);inventory=$inventory;errors=@($script:issues.ToArray());embedded=$embedded}
Write-Progress -Id 1 -Activity 'Discord package analysis' -Status 'Building self-contained HTML report' -PercentComplete 92
$css=@'
:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#15171e;color:#e6e8ef;font:14px Segoe UI,Arial,sans-serif}header{background:#232633;padding:16px 22px;display:flex;align-items:center;gap:20px;flex-wrap:wrap;position:sticky;top:0;z-index:5;border-bottom:1px solid #414455}h1{font-size:20px;margin:0;color:#fff}h2{font-size:18px}button,select,input{background:#252936;color:#f2f2f6;border:1px solid #484d60;border-radius:7px;padding:10px}button{cursor:pointer}button.active{background:#5865f2;border-color:#5865f2}input{width:100%;max-width:520px}.tabs{display:flex;gap:6px;flex-wrap:wrap}main{padding:20px;max-width:1450px;margin:auto}.summary{display:flex;gap:10px;flex-wrap:wrap}.chip{background:#303444;border-radius:20px;padding:7px 12px}.toolbar{display:flex;gap:10px;flex-wrap:wrap;margin:15px 0}.item{background:#20232d;border:1px solid #333746;border-radius:9px;margin:9px 0;padding:13px;overflow-wrap:anywhere}.meta{color:#a9aec0;font-size:12px;margin:5px 0}.name{font-weight:700;color:#b7c4ff}.body{white-space:pre-wrap;margin:9px 0;line-height:1.5}.media{display:inline-block;vertical-align:top;background:#2d3140;padding:10px;border-radius:9px;margin:7px;max-width:340px;overflow-wrap:anywhere}.media img,.media video{max-width:100%;max-height:300px;display:block;margin:7px 0}.media audio{max-width:100%}a{color:#a5baff}.muted{color:#abb0c2}.raw{white-space:pre-wrap;overflow-wrap:anywhere;background:#11131a;border-radius:7px;padding:12px;max-height:450px;overflow:auto}.hidden{display:none!important}.warning{color:#ffcc83}.count{font-size:12px;color:#aeb4c5}.file{border-bottom:1px solid #3a3e4d;padding:8px}details{margin-top:10px}summary{cursor:pointer}#results{max-height:none}
'@
$js=@'
const D=__PAYLOAD__;const $=x=>document.getElementById(x);const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const valid=u=>{try{const p=new URL(u);return ['http:','https:'].includes(p.protocol)?p.href:''}catch{return ''}};
const mediaType=(name,url)=>/\.(png|jpg|jpeg|gif|webp)(\?|$)/i.test(name||url)?'image':/\.(mp4|webm|mov)(\?|$)/i.test(name||url)?'video':/\.(mp3|ogg|wav|m4a)(\?|$)/i.test(name||url)?'audio':'file';
const attach=(a)=>{let u=typeof a==='string'?a:(a?.url||a?.proxy_url||a?.attachment_url||'');let name=typeof a==='string'?a.split('/').pop()?.split('?')[0]:(a?.filename||a?.name||u.split('/').pop()?.split('?')[0]||'Attachment');let kind=mediaType(name,u);let safe=valid(u);let embedded='';if(a?.path&&D.embedded[a.path])embedded=D.embedded[a.path];let src=embedded||safe;let out='<div class="media"><b>'+esc(name)+'</b><div class="meta">'+esc(kind)+'</div>';if(src&&kind==='image')out+='<img loading="lazy" src="'+esc(src)+'" alt="'+esc(name)+'">';if(src&&kind==='video')out+='<video controls preload="none" src="'+esc(src)+'"></video>';if(src&&kind==='audio')out+='<audio controls preload="none" src="'+esc(src)+'"></audio>';if(safe)out+='<a target="_blank" rel="noopener noreferrer" href="'+esc(safe)+'">Open original attachment</a>';else if(!embedded)out+='<div class="muted">No accessible media URL or embedded file</div>';return out+'</div>'};
const sections=['Overview','Messages','Media','Account','Activity','Activities','Ads','Servers','Support Tickets','Other','Files','Errors'];let tab='Overview';let page=0;const PAGE=200;
$('tabs').innerHTML=sections.map(s=>'<button data-tab="'+esc(s)+'">'+esc(s)+'</button>').join('');$('tabs').onclick=e=>{let b=e.target.closest('[data-tab]');if(b){tab=b.dataset.tab;page=0;render()}};
$('search').oninput=()=>{page=0;render()};$('channel').onchange=()=>{page=0;render()};$('prev').onclick=()=>{page=Math.max(0,page-1);render()};$('next').onclick=()=>{page++;render()};
const matches=(o,q)=>!q||JSON.stringify(o).toLowerCase().includes(q);
const getSection=s=>D.other.filter(x=>x.section.toLowerCase().replace(/[^a-z]/g,'')===s.toLowerCase().replace(/[^a-z]/g,''));
const listOther=(items,q)=>items.filter(x=>matches(x,q)).slice(page*PAGE,(page+1)*PAGE).map(x=>'<div class="item"><div class="name">'+esc(x.source)+'</div><details><summary>View JSON data</summary><pre class="raw">'+esc(JSON.stringify(x.data,null,2))+'</pre></details></div>').join('');
const card=m=>'<div class="item"><div class="name">'+esc(m.sender)+'</div><div class="meta">'+esc(m.timestamp)+' · '+esc(m.channel)+(m.participants?' · Participants: '+esc(m.participants):'')+' · Message ID: '+esc(m.id)+'</div><div class="body">'+esc(m.content)+'</div>'+((Array.isArray(m.attachments)?m.attachments:(m.attachments?[m.attachments]:[])).map(attach).join(''))+'<details><summary>Source</summary><div class="meta">'+esc(m.source)+' · Channel ID: '+esc(m.channelId)+'</div></details></div>';
function render(){document.querySelectorAll('[data-tab]').forEach(b=>b.classList.toggle('active',b.dataset.tab===tab));const q=$('search').value.toLowerCase(),ch=$('channel').value;let html='',count=0;
if(tab==='Overview'){html='<h2>Package summary</h2><div class="summary"><span class="chip">Account: '+esc(D.owner)+'</span><span class="chip">Messages: '+D.messages.length+'</span><span class="chip">Media references: '+D.media.length+'</span><span class="chip">Files: '+D.inventory.length+'</span><span class="chip">Parse issues: '+D.errors.length+'</span></div><p class="warning">Discord exports normally contain your own sent messages, not all replies. Participant names appear only when the export supplies them. Unresolved IDs are retained instead of guessed. Remote media requires internet access and may be expired or unavailable.</p><p>All parsed records are inside this HTML. Local media is embedded when present and within size limits; linked Discord attachments cannot be guaranteed to remain accessible.</p><h2>Channel metadata</h2>'+D.channels.map(c=>'<div class="item"><b>'+esc(c.name||c.people?.join(', ')||c.id)+'</b><div class="meta">'+esc(c.id)+' · '+esc(c.type)+' · '+esc((c.people||[]).join(', '))+'</div></div>').join('');}
else if(tab==='Messages'){let a=D.messages.filter(m=>(!ch||m.channel===ch)&&matches(m,q));count=a.length;html=a.slice(page*PAGE,(page+1)*PAGE).map(card).join('');}
else if(tab==='Media'){let a=D.media.filter(m=>(!ch||m.channel===ch)&&matches(m,q));count=a.length;html=a.slice(page*PAGE,(page+1)*PAGE).map(m=>'<div class="item"><div class="meta">'+esc(m.channel)+' · Message '+esc(m.message)+'</div>'+attach({url:m.url,filename:m.name,path:m.local})+'<div class="meta">'+esc(m.source)+'</div></div>').join('');}
else if(tab==='Files'){let a=D.inventory.filter(m=>matches(m,q));count=a.length;html=a.slice(page*PAGE,(page+1)*PAGE).map(f=>'<div class="file">'+esc(f.path)+' <span class="muted">('+f.bytes+' bytes)</span></div>').join('');}
else if(tab==='Errors'){let a=D.errors.filter(m=>matches(m,q));count=a.length;html=a.slice(page*PAGE,(page+1)*PAGE).map(e=>'<div class="item"><b>'+esc(e.File)+'</b><pre class="raw">'+esc(e.Error)+'</pre></div>').join('');}
else {let a=tab==='Other'?D.other.filter(x=>!sections.slice(3,9).some(s=>s.toLowerCase().replace(/[^a-z]/g,'')===x.section.toLowerCase().replace(/[^a-z]/g,''))):getSection(tab);a=a.filter(x=>matches(x,q));count=a.length;html=listOther(a,'');}
$('results').innerHTML=html||'<p class="muted">No matching records.</p>';$('counter').textContent=tab==='Overview'?'':count+' records · page '+(page+1)+' of '+Math.max(1,Math.ceil(count/PAGE));$('prev').disabled=page===0;$('next').disabled=(page+1)*PAGE>=count;$('pager').classList.toggle('hidden',tab==='Overview');$('channel').classList.toggle('hidden',!['Messages','Media'].includes(tab));}
$('channel').innerHTML='<option value="">All channels</option>'+[...new Set(D.messages.map(x=>x.channel))].sort().map(c=>'<option value="'+esc(c)+'">'+esc(c)+'</option>').join('');render();
'@
$html='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Discord Complete Viewer</title><style>'+$css+'</style></head><body><header><h1>Discord Complete Viewer</h1><nav id="tabs" class="tabs"></nav></header><main><div class="toolbar"><input id="search" placeholder="Search all fields in this section..."><select id="channel"></select></div><div id="counter" class="count"></div><div id="results"></div><div id="pager" class="toolbar"><button id="prev">Previous</button><button id="next">Next</button></div></main><script>'+$js.Replace('__PAYLOAD__',(Js $payload))+'</script></body></html>'
[IO.File]::WriteAllText($OutputFile,$html,[Text.UTF8Encoding]::new($false))
Write-Progress -Id 1 -Activity 'Discord package analysis' -Completed
Write-Host "`nFinished! Messages: $($script:entries.Count) | Media references: $($script:media.Count) | Parse issues: $($script:issues.Count)" -ForegroundColor Green
Write-Host "Single HTML report: $OutputFile" -ForegroundColor Green
Start-Process -FilePath $OutputFile
