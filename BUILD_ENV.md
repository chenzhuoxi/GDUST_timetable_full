# Build Environment Record

## v5 Release (2026-06-14 04:10)

CAS 扫码登录 + SSE 流式抓取，合并 Lite 版 UI 基础

| 组件 | 版本 |
|------|------|
| Flutter | 3.24.5 (Dart 3.5.4) |
| JDK | OpenJDK 21.0.10 (Homebrew) |
| AGP (Android Gradle Plugin) | 8.3.0 |
| Gradle | 8.9 |
| Kotlin | 1.9.10 |
| compileSdkVersion | 35 |
| NDK | 25.1.8937393 |
| macOS | Darwin 25.4.0 (arm64) |
| APK 大小 | 22.5MB |
| 包名 | com.jikuai.gdust_full |

## 当前保留依赖

| 组件 | 路径 | 大小 |
|------|------|------|
| Flutter 3.24.5 | ~/fvm/versions/3.24.5 | 908MB |
| Gradle 8.9 | ~/.gradle/wrapper/dists/gradle-8.9-all | 707MB |
| Gradle 8.9 缓存 | ~/.gradle/caches/8.9 | ~1GB |
| JDK 21 | Homebrew OpenJDK | 系统管理 |

## 历史编译记录

### v1-v4 (2026-06-12 ~ 2026-06-13)
- 早期用 Flutter 3.7.12 + JDK 17，file_picker 兼容性问题
- 后升级到 Flutter 3.24.5 + JDK 21 解决

## 已清理依赖 (2026-06-14)

| 清理项 | 大小 | 原因 |
|--------|------|------|
| Flutter 3.7.12 | 2.6GB | 已被 3.24.5 替代 |
| Flutter 3.22.0 | 3.6GB | 未使用 |
| Gradle 7.3/7.5/7.6.3/8.3/8.5/8.7 wrapper | 3.5GB | 已被 8.9 替代 |
| Gradle 旧版本缓存 | ~1GB | 版本缓存 |
| **合计释放** | **~10.7GB** | |

## 已知编译陷阱

1. **JDK 21 + Gradle ≤7.5** — 不兼容，需 Gradle ≥8.5
2. **file_picker 4.x + AGP 8.x** — namespace 未声明，编译失败
3. **file_picker 5.x + Dart <3.0** — 版本约束不满足
4. **compileSdk 33 + JDK 21** — 不兼容，需 compileSdk ≥34
