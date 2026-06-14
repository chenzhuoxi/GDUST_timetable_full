# 广科课表 (GDUST Timetable Full)

广东科技学院（GDUST）课表查看工具 Full 版 —— 内置 CAS 登录 + 自动抓取 + 课前提醒，一站式解决课表需求。

## ✨ 功能

- 📋 **网格/列表双视图** — 一周课表一目了然
- 👆 **左右滑动切换星期** — 手势操作，tab 同步联动
- 🎨 **课程卡片颜色条** — 每门课固定配色，已过课程自动变灰
- ⏰ **上课倒计时** — 实时显示距下一节课的时间
- 🔀 **连续课程合并** — 同一门连排课自动合并显示
- 📁 **文件/剪贴板导入** — 两种方式导入 JSON
- 💾 **本地缓存** — 首次导入后自动缓存，后续无需重复导入
- 📱 **拟态风格桌面小组件** — 主屏幕显示今日课程
- 🔐 **CAS 统一认证登录** — 内置登录，无需额外工具
- 🤖 **自动抓取课表** — 登录后一键拉取全学期 20 周数据
- 🔔 **课前提醒** — 上课前自动推送提醒
- 🔄 **检查更新** — 应用内检测新版本

## 📦 下载

| 版本 | 大小 | 下载 |
|------|------|------|
| v1.0.6 | ~20MB | [gdust_full_v1.0.6.apk](../../releases/latest) |

> 包名 `com.jikuai.gdust_full`，与 Lite 版可共存。

## 📖 使用

### 方式一：自动抓取（推荐）

1. 打开 App → 进入登录页面
2. 输入校园网账号密码 → 登录
3. 自动拉取全学期课表 → 完成

### 方式二：手动导入

从 [gdust-timetable](https://github.com/chenzhuoxi/GDUST_timetable) 导出 JSON 后，通过文件或剪贴板导入。

## 🔧 从源码编译

```bash
cd gdust_timetable_app
flutter pub get
flutter build apk --release
```

> 需要 Flutter 3.24.5+ 和 JDK 17+。详见项目内 `BUILD_ENV.md`。

## 📝 与 Lite 版的区别

| | Full 版 | Lite 版 |
|---|---------|---------|
| 课表展示 | ✅ | ✅ |
| 文件/剪贴板导入 | ✅ | ✅ |
| CAS 登录 / 自动抓取 | ✅ | ❌ |
| 课前提醒 | ✅ | ❌ |
| 检查更新 | ✅ | ❌ |

> 💡 只需要查看课表、不需要自动抓取？试试 [Lite 版](https://github.com/chenzhuoxi/GDUST_timetable_lite)，更轻量。

## 相关项目

- [GDUST_timetable](https://github.com/chenzhuoxi/GDUST_timetable) — 课表抓取工具（命令行 + Web GUI），支持 CAS 登录、自动验证码识别
- [GDUST_timetable_lite](https://github.com/chenzhuoxi/GDUST_timetable_lite) — 课表查看工具 Lite 版，导入 JSON 即用，更轻量

## License

[MIT](LICENSE)
