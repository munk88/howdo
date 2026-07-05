---
title: "从零理解 CSS Grid：一份图解指南"
description: "CSS Grid 是现代布局的核心工具。这篇文章用图解的方式讲清楚 Grid 的所有核心概念，包括容器属性、项目属性、以及实战布局模式。"
pubDate: 2026-06-15
tags: ["技术"]
readingTime: 15
---

CSS Grid 是现代布局的核心工具。这篇文章用图解的方式讲清楚 Grid 的所有核心概念。

## 为什么需要 Grid

Flexbox 是一维布局（横向或纵向），Grid 是二维布局（同时控制行和列）。当你需要复杂的网格结构时，Grid 是唯一正确的选择。

## 核心概念

```css
.container {
  display: grid;
  grid-template-columns: 1fr 2fr 1fr;
  grid-template-rows: auto 200px;
  gap: 20px;
}
```

这会创建一个 3 列 2 行的网格，中间列宽度是两侧的两倍。

## 实战：经典三栏布局

```html
<div class="layout">
  <header>Header</header>
  <nav>Sidebar</nav>
  <main>Content</main>
  <footer>Footer</footer>
</div>
```

```css
.layout {
  display: grid;
  grid-template-areas:
    "header header"
    "sidebar content"
    "footer footer";
  grid-template-columns: 200px 1fr;
  grid-template-rows: auto 1fr auto;
  min-height: 100vh;
}
```

> Grid 的 `grid-template-areas` 是最直观的布局语法，像画图一样定义结构。

## 总结

Grid 不是 Flexbox 的替代品，而是补充。一维用 Flex，二维用 Grid，这是现代 CSS 布局的黄金法则。
