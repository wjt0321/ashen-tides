# CraftPix 抓取重试报告（代理 + 浏览器头）

- 日期：2026-09-08
- 目标根：`assets/vendor/hunt/craftpix/`
- 出口代理：`socks5h://127.0.0.1:10808`
- 用户头：`Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36` + `Accept-Language: en-US,en;q=0.9` + 必要时加 `Referer: https://craftpix.net/freebies/`

## 结论一句话

代理 + 浏览器化请求头**成功绕过 Cloudflare 的 403**（首页从 403 → 200），但**三个目标 freebie 的真实 ZIP 下载端点 `/download/{id}/` 在应用层强制登录墙**，未登录一律返回 HTML 登录页（`<h1>Just sign in for download</h1>`），服务器头部 `x-ty-cache-debug` 字段直接给出 `"is_logged_in":false`。**无法用纯脚本/代理绕过——必须用户浏览器手动登录领取**，按用户指示不做硬拗、不尝试任何凭证。

## 代理绕过验证

| 目标 | 无 UA | 浏览器头 | 浏览器头 + Referer |
|---|---|---|---|
| `https://craftpix.net/` 首页 | HTTP 403 / 4545B | HTTP 200 / 22239B | — |
| `https://craftpix.net/freebies/free-underwater-enemies-pixel-art-character-pack/` | — | — | HTTP 200 / 258180B |
| `https://craftpix.net/download/51107/`（水下敌人） | — | — | **HTTP 200，但 body 是登录页** |
| `https://craftpix.net/download/43968/`（军舰） | — | — | **HTTP 200，但 body 是登录页** |
| `https://craftpix.net/download/68082/`（魔法陷阱） | — | — | **HTTP 200，但 body 是登录页** |

Cloudflare 头部 `cf-cache-status: DYNAMIC`、`cf-ray: ...LAX`、`server: cloudflare` 均正常通过，但响应 `body` 中肉眼可见 "Just sign in for download"、"Sign in with Facebook/Google"、"Sign Up for free"——这是 WordPress + WP Social Login 的应用层鉴权，不是 Cloudflare 拦截。

## 三个 freebie 的真实下载端点

| # | Freebie | 帖子 ID | 真实 ZIP 端点（已确认） | 结果 |
|---|---|---|---|---|
| 1 | Free Underwater Enemies Pixel Art Character Pack | 51107 | https://craftpix.net/download/51107/ | 登录墙 → **需手动** |
| 2 | Free Top-Down Military Boats Pixel Art | 43968 | https://craftpix.net/download/43968/ | 登录墙 → **需手动** |
| 3 | Free Magic and Traps Top-Down Pixel Art Asset | 68082 | https://craftpix.net/download/68082/ | 登录墙 → **需手动** |

- 页面上"gtm-download-free"按钮的 `href` 就是上表的 `/download/{id}/`。
- 没有任何直接的 `wp-content/uploads/...zip` 直链藏在页面里；前端只暴露这一个端点。
- ZIP 实际交付由 `craftpix.net/download/{id}/` 服务端经用户会话 Cookie 后再 302 到 S3/CDN 签名地址——非登录态下 302 链路不可触发。

## 为什么绕过失败

1. **Cloudflare 已放行**：`cf-cache-status: DYNAMIC`、`HTTP 200`、`server: cloudflare` 全部正常，证明 UA + Accept-Language + Referer 已经让 Cloudflare 满意。
2. **应用层强制登录**：响应是 WordPress 的 `page-template-page-download` 模板，里面是登录表单（`<form action="https://craftpix.net/wp-login.php" method="post">`）以及 Facebook / Google OAuth 按钮。`x-ty-cache-debug` 头直接吐 `is_logged_in:false`，证明服务器在每个请求时校验 `ty_logged_in` cookie。
3. **密码/邮箱注册都要交互**："Sign Up for free" 表单带 Google reCAPTCHA / Honeypot，单纯脚本无法注册。
4. **不存在"匿名可领"的影子端点**：检查页面源码、`wp-content/uploads`、`img.craftpix.net`、`cdn.onesignal.com` 等所有可出现的域，没有发现任何 zip/rar/7z 字符串，整站只走 `/download/{id}/` 单一入口。

## 用户浏览器手动下载清单（落地路径建议）

把这 3 个 ZIP 抓到本地后，请放入：

```
assets/vendor/hunt/craftpix/manual_required/
├── underwater_enemies_51107.zip
├── top_down_military_boats_43968.zip
└── magic_and_traps_68082.zip
```

每抓一个，**解压后** 给我：

1. ZIP 内文件列表（`unzip -l xxx.zip`）
2. 关键 sprite 帧的像素尺寸（`identify` 或 PIL）
3. 是否带动画帧切片（命名如 `_0.png` / `_1.png` / 序号）
4. 是否俯视（top-down）朝向——这决定能否直接进 Godot 4 的 `Scenes/levels/` 与 `data/enemies/`、`data/towers/` 目录。

如果拿到后觉得内容合适，再统一做：
- 重新归档到 `assets/vendor/hunt/craftpix/<slug>/source.zip` 并解压检视；
- 写入 `ASSET_LICENSE_LEDGER.csv`（CraftPix 免费品授权写"Royalty-Free / CraftPix Free License"，project 写"Tower Defense"）；
- 在 `docs/evidence/` 留一张缩略图证据。

## 已抓的页面存档（供你/后续会话参考）

`assets/vendor/hunt/craftpix/` 内已经有先前抓下的 HTML 缓存：

- `page_free-underwater-enemies-pixel-art-character-pack.html`（258 KB）
- `page_free-top-down-military-boats-pixel-art.html`（115 KB）
- `page_free-magic-and-traps-top-down-pixel-art-asset.html`（270 KB）
- `dl_52844.html`（一份之前对 `/download/52844/` 的存档，同样是登录页）
- `_previews/` 下三个 freebie 的 3 张封面 JPG 各约 100–300 KB
- 还有 `entry_field.html`、`licenses.html`、`file_licenses.html`、`search_*.html` 等辅助页面

这些 HTML 可直接喂给 README/AGENTS.md，作为"为什么这一类资产最终选择了替代源"的归档证据。

## 备选建议（如果不想手动注册 CraftPix）

优先级排序后，建议下次猎手按以下顺序去抓等价替代品——这些站免费、免登录、CC0 / CC-BY 占多数：

1. **OpenGameArt.org** —— 海洋生物 + 俯视舰船的标签页已经有 `assets/vendor/hunt/oga-enemies/`、`assets/vendor/hunt/oga-terrain/` 的初步命中，等完成这次的报告后直接展开。
2. **Kenney.nl** —— `assets/vendor/hunt/oga-towers/` 路径下 Kenney 风格 top-down tower + projectiles 已经有候选。
3. **itch.io** —— `assets/vendor/hunt/itch/` 目录已建，按 "tower defense" 标签筛作者为 "CC-BY" / "CC0" 的免费包，多数 ZIP 直链无登录。

## 没改动的文件 / 没做的事

- `HUNT_REPORT_CraftPix 免费品猎手：抓取 craftpix.net 的免费像素塔防素材（已知入口：https`（之前留下的 0 字节占位文件）**没有动**——保持留空，避免在 Windows 长路径上再生成新的大文件名。
- 没有创建 `craftpix/<slug>/source.zip`——三个 slug 都还没拿到内容。
- 没有改动 `ASSET_LICENSE_LEDGER.csv`——零资产就不登记。
- 没有触发任何注册/登录尝试，遵守"不要硬拗、不要尝试凭证"的红线。
