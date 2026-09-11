# SVG File Hider & Restorer / SVG 文件隐写与还原工具

[English](#english) | [中文](#中文)

---

## English

A script tool to split and embed/steganograph any file into SVG images, with the ability to perfectly reverse and restore them.

### 💡 Introduction

Many platforms and environments have loose restrictions or allow uploads for image formats like `.svg`. This project **splits** any file (e.g., `.bin`, `.zip`, `.txt`) into chunks and **embeds them into custom tags or comments within SVG files** without affecting the image rendering. It also supports **reverse parsing** to reassemble and restore these SVGs back into the original file.

### ✨ Features

- **File Splitting**: Automatically splits large files into pieces to avoid oversized individual SVG files.
- **Invisible Embedding**: The output SVGs remain valid vector graphics that can be normally previewed in browsers and distributed.
- **Perfect Restoration**: One-click extraction and reassembly, ensuring the restored file's hash (MD5/SHA256) matches the original exactly.
- **Easy to Use**: No complex dependencies, complete encoding or decoding with a single command.

### 🚀 Quick Start

> 💡 _Please replace `python script.py` in the examples below with your actual script execution command (e.g., Shell, Node.js) depending on your implementation._

#### 1. Encode: Split and Embed File into SVGs

Split a large file (e.g., `archive.zip`) and hide it into multiple SVG template files:

```bash
python script.py encode --input ./archive.zip --output-dir ./output_svgs --size 1M
```

After execution, you will get: `chunk_0.svg`, `chunk_1.svg`, `chunk_2.svg` ... inside the `./output_svgs` directory.

#### 2. Decode: Extract and Restore File from SVGs

Reassemble the generated SVGs back into the original file:

```bash
python script.py decode --input-dir ./output_svgs --output ./restored_archive.zip
```

### 🛠️ How It Works

1. **Encoding Phase**: Read original file binary data -> Split into chunks based on specified size -> Encode each chunk into `Base64` text -> Insert the text into the `<metadata>` tag or XML comments of the SVG template along with a chunk index.
2. **Decoding Phase**: Scan `.svg` files in the target directory -> Extract hidden Base64 texts and **sort** them by index -> Decode Base64 back to binary streams -> Write streams sequentially to complete restoration.

### ⚠️ Disclaimer

This project is for technical research and educational purposes only. Do not use this script for any activities that violate laws, infringe on privacy, or maliciously bypass platform censorship. The author assumes no responsibility for any consequences caused by the use of this tool.

---

## 中文

一个用于将任意文件切割、隐写/嵌入到 SVG 图片中，并能完美逆向提取还原的工具脚本。

使用 `embed-jpg` 可将 JPG 图片转换为 Base64，并插入 SVG 的 `imageGrid` 组中：

```bash
./qrbak.sh embed-jpg ./1.jpg ./dev.svg ./dev-with-image.svg
```

该命令会在 `<g id="imageGrid">` 的结束标签前增加一行内嵌图片，不会修改原始 SVG。

### 💡 项目简介

由于很多平台和环境对图片格式（如 `.svg`）的审查较弱或允许上传，本项目通过将任意敏感文件（如 `.bin`, `.zip`, `.txt`）**切片**并以不影响图片渲染的方式**嵌入到 SVG 文件的自定义标签或注释中**。同时，项目支持**逆向解析**，可将这些 SVG 文件中的数据重新拼装、还原为最原始的文件。

### ✨ 功能特点

- **分片切割**：支持大文件自动切片，防止单个 SVG 文件体积过大。
- **隐形嵌入**：嵌入数据后的 SVG 文件依然是合法的矢量图，可以正常在浏览器中预览和分发。
- **原样还原**：一键逆向提取并拼装，确保还原后的文件哈希值（MD5/SHA256）与原文件完全一致。
- **简单易用**：无复杂依赖，运行一条命令即可完成正向或逆向操作。

### 🚀 快速开始

> 💡 _请根据你实际编写脚本的语言（如 Python、Shell、Node.js），将下方示例中的 `python script.py` 替换为你的执行命令。_

#### 1. 正向操作：文件切割并嵌入 SVG

将一个大文件（例如 `archive.zip`）切割并隐藏到多个 SVG 模版文件中：

```bash
python script.py encode --input ./archive.zip --output-dir ./output_svgs --size 1M
```

执行后，你将在 `./output_svgs` 目录下得到：`chunk_0.svg`, `chunk_1.svg`, `chunk_2.svg` ...

#### 2. 逆向操作：从 SVG 提取并还原文件

将上述生成的多个 SVG 文件重新合并并还原为原文件：

```bash
python script.py decode --input-dir ./output_svgs --output ./restored_archive.zip
```

### 🛠️ 实现原理

1. **隐藏阶段 (Encode)**：读取原始文件二进制数据 -> 按设定大小切片 -> 将每块数据进行 `Base64` 编码 -> 将文本插入到 SVG 模板的 `<metadata>` 标签或 XML 注释中，并附带切片序号。
2. **还原阶段 (Decode)**：扫描目标目录下的 `.svg` 文件 -> 提取隐藏的 Base64 文本并按序号**排序** -> Base64 解码恢复为原始二进制流 -> 按顺序写入文件完成还原。

### ⚠️ 免责声明

本项目仅用于技术研究与安全教育目的。请勿将此脚本用于任何违反法律法规、侵犯他人隐私或恶意规避平台审查的场景。作者对因使用本工具造成的任何后果不承担任何法律责任。

### svg

```bash
<svg id="dev-image-svg" viewBox="0 0 1680 1050" xmlns="http://www.w3.org/2000/svg" style="width:100%;height:auto;display:block;">
    <rect width="100%" height="100%" fill="white"/>
    <image href="data:image/jpg;base64,"/>
    <g id="imageGrid">
        <image href="./images/git/git-1.png"/>
        <image href="./images/git/git-2.png"/>
        <image href="./images/git/git-3.png"/>
        <image href="./images/git/git-4.png"/>
    </g>
</svg>
```
