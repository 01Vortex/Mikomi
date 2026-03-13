# Flutter项目结构详解

## 项目概述

**项目名称**: mikomi  
**项目类型**: Flutter应用  
**Flutter版本**: Stable Channel  
**Dart SDK**: ^3.11.1  
**项目版本**: 1.0.0+1

这是一个标准的Flutter跨平台应用项目,支持Android、iOS、Web、Windows、Linux和macOS平台。

## 目录结构

```
mikomi/
├── .dart_tool/              # Dart工具生成的文件(自动生成,不应手动修改)
│   ├── dartpad/            # DartPad相关配置
│   ├── flutter_build/      # Flutter构建缓存
│   ├── package_config.json # 包配置信息
│   ├── package_graph.json  # 包依赖图
│   └── version             # 工具版本信息
│
├── .git/                    # Git版本控制目录
├── .idea/                   # IntelliJ IDEA/Android Studio配置
├── .kiro/                   # Kiro AI助手配置
│   └── steering/
│       └── rule.md         # 项目开发规则
│
├── android/                 # Android平台特定代码
│   ├── app/
│   │   ├── src/
│   │   │   ├── debug/      # Debug构建配置
│   │   │   ├── main/       # 主要代码和资源
│   │   │   │   ├── java/   # Java代码(插件注册)
│   │   │   │   ├── kotlin/ # Kotlin代码(MainActivity)
│   │   │   │   └── res/    # Android资源文件
│   │   │   └── profile/    # Profile构建配置
│   │   └── build.gradle.kts # 应用级Gradle配置
│   ├── gradle/             # Gradle包装器
│   ├── build.gradle.kts    # 项目级Gradle配置
│   ├── settings.gradle.kts # Gradle设置
│   └── gradle.properties   # Gradle属性配置
│
├── ios/                     # iOS平台特定代码
│   ├── Flutter/            # Flutter iOS配置
│   │   ├── Debug.xcconfig  # Debug配置
│   │   ├── Release.xcconfig # Release配置
│   │   └── ephemeral/      # 临时生成文件
│   └── Runner/             # iOS应用主体
│       ├── Assets.xcassets/ # iOS资源文件
│       ├── Base.lproj/     # 本地化资源
│       ├── AppDelegate.swift # 应用委托
│       └── Info.plist      # iOS应用配置
│
├── linux/                   # Linux平台特定代码
├── macos/                   # macOS平台特定代码
├── web/                     # Web平台特定代码
├── windows/                 # Windows平台特定代码
│
├── lib/                     # Dart源代码目录(核心开发目录)
│   └── main.dart           # 应用入口文件
│
├── test/                    # 测试代码目录
│   └── widget_test.dart    # Widget测试文件
│
├── build/                   # 构建输出目录(自动生成)
├── docs/                    # 项目文档目录
│
├── .gitignore              # Git忽略文件配置
├── .metadata               # Flutter项目元数据
├── analysis_options.yaml   # Dart代码分析配置
├── pubspec.yaml            # 项目依赖和配置文件
├── pubspec.lock            # 依赖版本锁定文件
├── README.md               # 项目说明文档
└── mikomi.iml              # IntelliJ模块配置文件
```

## 核心目录说明

### 1. lib/ - 应用源代码

这是Flutter应用的核心开发目录,所有Dart代码都应放在这里。

**重构后的关键文件**:
- `main.dart`: 应用入口,仅负责启动应用
- `app.dart`: 应用根Widget,配置MaterialApp、主题、路由
- `config/routes/app_routes.dart`: 集中管理所有路由
- `config/themes/app_theme.dart`: 统一主题配置(支持亮色/暗色模式)
- `features/home/presentation/pages/home_page.dart`: 首页
- `features/home/presentation/widgets/counter_display.dart`: 计数器显示组件

**当前结构(已重构)**:
```
lib/
├── main.dart                    # 应用入口
├── app.dart                     # 应用根Widget配置
│
├── config/                      # 全局配置
│   ├── routes/                 # 路由配置
│   │   └── app_routes.dart    # 路由定义
│   └── themes/                 # 主题配置
│       ├── app_theme.dart     # 主题定义
│       └── app_colors.dart    # 颜色常量
│
├── core/                        # 核心功能(跨功能模块共享)
│   ├── constants/              # 全局常量
│   │   └── app_constants.dart
│   ├── models/                 # 核心数据模型
│   ├── services/               # 核心服务(API、存储等)
│   └── utils/                  # 工具类
│
├── features/                    # 功能模块(按业务划分)
│   └── home/                   # 首页功能模块
│       ├── data/               # 数据层(数据源、仓库实现)
│       ├── domain/             # 领域层(实体、仓库接口、用例)
│       └── ui/       # 表现层(UI)
│           ├── pages/         # 页面
│           │   └── home_page.dart
│           └── widgets/       # 页面专用组件
│               └── counter_display.dart
│
└── shared/                      # 共享资源
    ├── widgets/                # 通用UI组件
    └── utils/                  # 共享工具函数
```

**架构说明**:
- 采用Clean Architecture + Feature-First架构
- 每个功能模块独立,包含完整的data/domain/presentation三层
- core存放跨模块共享的核心功能
- shared存放可复用的UI组件和工具
- config存放全局配置(路由、主题等)

### 2. android/ - Android平台代码

包含Android平台特定的配置和原生代码。

**关键文件**:
- `app/build.gradle.kts`: 应用级构建配置
- `app/src/main/AndroidManifest.xml`: Android应用清单
- `app/src/main/kotlin/.../MainActivity.kt`: Android主Activity
- `gradle.properties`: Gradle属性配置

### 3. ios/ - iOS平台代码

包含iOS平台特定的配置和原生代码。

**关键文件**:
- `Runner.xcodeproj/`: Xcode项目文件
- `Runner/Info.plist`: iOS应用配置
- `Runner/AppDelegate.swift`: iOS应用委托
- `Flutter/`: Flutter iOS配置文件

### 4. web/ - Web平台代码

包含Web平台特定的HTML、CSS和JavaScript文件。

### 5. windows/linux/macos/ - 桌面平台代码

包含各桌面平台特定的原生代码和配置。

### 6. test/ - 测试代码

包含单元测试、Widget测试和集成测试。

**当前文件**:
- `widget_test.dart`: Widget测试示例

## 配置文件说明

### pubspec.yaml

项目的核心配置文件,定义:

**基本信息**:
- 项目名称: mikomi
- 描述: A new Flutter project
- 版本: 1.0.0+1
- Dart SDK要求: ^3.11.1

**依赖包**:
- `flutter`: Flutter SDK
- `cupertino_icons: ^1.0.8`: iOS风格图标

**开发依赖**:
- `flutter_test`: 测试框架
- `flutter_lints: ^6.0.0`: 代码规范检查

**Flutter配置**:
- `uses-material-design: true`: 启用Material Design图标

### analysis_options.yaml

Dart代码静态分析配置,使用`flutter_lints`推荐的规则集。

### .metadata

Flutter项目元数据,记录:
- Flutter版本和渠道
- 项目类型
- 平台创建信息
- 不受管理的文件列表

## 平台支持

项目支持以下平台:
- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ Linux
- ✅ macOS

所有平台都基于同一个Flutter revision创建,确保跨平台一致性。

## 开发规则

项目遵循`.kiro/steering/rule.md`中定义的开发规范:
- 使用中文进行开发和文档编写
- 遵循最佳实践,避免冗余代码
- 批处理文件使用UTF-8无BOM编码
- 代码注重可读性,避免过度复杂
- 遵循组件化、模块化开发原则
- 使用真实API数据后删除模拟数据

## 构建和运行

**开发运行**:
```bash
flutter run
```

**构建发布版本**:
```bash
# Android
flutter build apk
flutter build appbundle

# iOS
flutter build ios

# Web
flutter build web

# Windows
flutter build windows

# Linux
flutter build linux

# macOS
flutter build macos
```

**运行测试**:
```bash
flutter test
```

**代码分析**:
```bash
flutter analyze
```

## 重构完成内容

已完成以下重构:
- 采用Clean Architecture + Feature-First架构
- 分离关注点:配置、核心功能、业务功能、共享资源
- 实现主题系统(支持亮色/暗色模式)
- 集中式路由管理
- 组件化开发(页面与组件分离)
- 更新测试文件适配新架构

## 下一步扩展建议

1. 添加状态管理方案(Provider、Riverpod、Bloc等)
2. 添加网络请求库(dio)和API服务层
3. 配置本地存储(shared_preferences、hive)
4. 添加国际化支持(flutter_localizations)
5. 完善各功能模块的data/domain层
6. 增加更多共享组件到shared/widgets
7. 完善测试覆盖率
