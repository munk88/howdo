---
title: "周末项目：用 Rust 写一个命令行天气工具"
description: "这个周末我用 Rust 写了一个命令行天气查询工具。这篇文章记录了从需求分析、crate 选择、到最终实现的完整过程。"
pubDate: 2026-05-20
tags: ["技术"]
readingTime: 10
---

这个周末我用 Rust 写了一个命令行天气查询工具。这篇文章记录了完整过程。

## 需求

我想要一个能在终端里快速查天气的工具：

- 输入城市名，返回当前天气
- 支持多城市配置
- 响应时间 < 1 秒
- 单二进制文件，无运行时依赖

## 技术选型

| 需求 | 选择 | 理由 |
|------|------|------|
| HTTP 客户端 | `reqwest` | 生态最成熟，支持 async |
| JSON 解析 | `serde_json` | Rust 事实标准 |
| 命令行参数 | `clap` | 类型安全，自动生成 help |
| 配置文件 | `toml` + `serde` | TOML 比 JSON 更适合人类编辑 |

## 核心代码

```rust
#[derive(Deserialize)]
struct Weather {
    temp: f64,
    description: String,
}

async fn get_weather(city: &str, api_key: &str) -> Result<Weather, reqwest::Error> {
    let url = format!("https://api.weather.com/v1?q={}&appid={}", city, api_key);
    reqwest::get(&url).await?.json::<Weather>().await
}
```

> Rust 的错误处理初看繁琐，但用熟之后你会发现它让代码的边界条件变得清晰可见。

## 总结

整个项目不到 300 行代码，编译后二进制 2.4MB。Rust 的学习曲线值得爬，类型系统帮你挡住了大量运行时错误。
