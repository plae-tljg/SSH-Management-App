# SSH Manager 开发指南

## 开发环境要求

- Flutter SDK: 3.19.0 或更高版本
- Dart SDK: 3.3.0 或更高版本
- Android Studio: 2023.1.1 或更高版本
- Android SDK: 34.0.0 或更高版本
- JDK: 17 或更高版本
- Git: 2.40.0 或更高版本

## 项目结构

项目采用清晰的分层架构，遵循领域驱动设计(DDD)原则：

```
lib/
├── core/                 # 核心功能模块
│   ├── config/          # 应用配置
│   ├── di/              # 依赖注入
│   ├── ssh/             # SSH连接管理
│   └── utils/           # 工具类
│
├── features/            # 功能模块
│   ├── terminal/        # 终端功能
│   │   ├── data/       # 数据层
│   │   ├── domain/     # 领域层
│   │   └── presentation/# 表现层
│   │
│   ├── file_manager/   # 文件管理功能
│   │   ├── data/       # 数据层
│   │   ├── domain/     # 领域层
│   │   └── presentation/# 表现层
│   │
│   └── connection/     # 连接管理功能
│       ├── data/       # 数据层
│       ├── domain/     # 领域层
│       └── presentation/# 表现层
```

## 代码风格指南

### 命名规范

1. 文件命名：
   - 使用小写字母和下划线
   - 例如：`file_manager_repository.dart`

2. 类命名：
   - 使用大驼峰命名法
   - 例如：`FileManagerRepository`

3. 变量和函数命名：
   - 使用小驼峰命名法
   - 例如：`uploadFile()`, `currentPath`

### 代码组织

1. 每个功能模块应包含：
   - 数据层（data）：处理数据存储和网络请求
   - 领域层（domain）：包含业务逻辑和实体
   - 表现层（presentation）：处理UI和用户交互

2. 依赖注入：
   - 使用依赖注入管理模块间依赖
   - 通过接口定义明确的契约
   - 避免直接依赖具体实现

### 最佳实践

1. 错误处理：
   - 使用 try-catch 处理异常
   - 提供有意义的错误信息
   - 在UI层显示用户友好的错误提示

2. 状态管理：
   - 使用 StreamController 管理状态
   - 避免直接修改状态
   - 通过事件驱动更新UI

3. 异步操作：
   - 使用 async/await 处理异步操作
   - 避免回调地狱
   - 正确处理异步错误

4. 测试：
   - 编写单元测试
   - 测试业务逻辑
   - 模拟外部依赖

## 开发流程

1. 分支管理：
   - main：主分支，保持稳定
   - develop：开发分支
   - feature/*：功能分支
   - bugfix/*：修复分支

2. 提交规范：
   - feat: 新功能
   - fix: 修复bug
   - docs: 文档更新
   - style: 代码格式
   - refactor: 重构
   - test: 测试
   - chore: 构建过程或辅助工具的变动

3. 代码审查：
   - 提交PR前进行自测
   - 确保代码符合规范
   - 添加必要的测试
   - 更新相关文档

## 配置说明

1. Android配置：
   - 在 `android/app/build.gradle` 中设置版本信息
   - 在 `android/app/src/main/AndroidManifest.xml` 中配置权限

2. 环境变量：
   - 使用 `.env` 文件管理环境变量
   - 不要提交包含敏感信息的配置文件

3. 依赖管理：
   - 在 `pubspec.yaml` 中管理依赖
   - 指定具体的版本号
   - 定期更新依赖

## 调试指南

1. 日志：
   - 使用 `print` 或日志库记录关键信息
   - 在发布版本中禁用详细日志

2. 断点调试：
   - 使用 IDE 的调试工具
   - 设置条件断点
   - 查看变量状态

3. 性能分析：
   - 使用 Flutter DevTools
   - 监控内存使用
   - 分析渲染性能

## 发布流程

1. 版本号管理：
   - 遵循语义化版本规范
   - 主版本号：不兼容的API修改
   - 次版本号：向下兼容的功能性新增
   - 修订号：向下兼容的问题修正

2. 构建发布版本：
   - 清理项目：`flutter clean`
   - 获取依赖：`flutter pub get`
   - 构建APK：`flutter build apk --release`

3. 发布检查清单：
   - 更新版本号
   - 更新更新日志
   - 运行所有测试
   - 检查性能
   - 验证所有功能 