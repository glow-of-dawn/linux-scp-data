# SVG File Embedder / SVG 文件嵌入与还原工具

[English](#english) | [中文](#中文)

---

## English

`splitfile.sh` stores a file as Base64 data inside one generated SVG, then restores that embedded data to a file. It is intended for Linux, WSL, or another Bash environment with GNU core utilities.

### Requirements

- Bash
- GNU `base64`, `split`, `find`, `sort`, `awk`, `tr`, and `/dev/urandom`
- A cover image file named `main-image.base64` in the working directory

`main-image.base64` must contain the Base64 text of a JPG image. It is placed in the SVG's first `<image>` element so the SVG has a visible cover image.

Create it from a JPG:

```bash
base64 -w 0 cover.jpg > main-image.base64
```

### Usage

Make the script executable once:

```bash
chmod +x splitfile.sh
```

#### Encode

```bash
./splitfile.sh encode <source-file> [split-size]
```

The source file is Base64-encoded, split into fragments, and written as `<image data="...">` elements in a newly generated SVG. The SVG is saved in the current directory under a random five-letter name, for example `AbcDe.svg`. Temporary fragments are stored in `./source` while processing and removed afterwards.

Example:

```bash
./splitfile.sh encode archive.zip
```

The script currently defaults to a fragment size of `200k`. The intended optional size syntax is supported by GNU `split`, such as `1K`, `200k`, or `2M`:

```bash
./splitfile.sh encode archive.zip 1M
```

> Note: in the current script, the optional size is assigned only when the argument count is not three. Therefore the explicit `1M` example may not take effect until that condition is corrected in the script. The default `200k` does work.

#### Decode

```bash
./splitfile.sh decode <input-svg> <output-file>
```

The script extracts all `<image>` elements that contain a `data` attribute, concatenates their Base64 payloads in document order, and decodes them to the output file.

Example:

```bash
./splitfile.sh decode AbcDe.svg restored.zip
```

Verify the restored result:

```bash
sha256sum archive.zip restored.zip
```

### Generated SVG Structure

The generated SVG contains a visible JPG cover followed by the embedded data fragments:

```xml
<svg ...>
    <rect width="100%" height="100%" fill="white"/>
    <image href="data:image/jpg;base64,..."/>
    <g id="imageGrid">
        <image data="./source/image.000" href="data:image/jpg;base64,..."/>
        <image data="./source/image.001" href="data:image/jpg;base64,..."/>
    </g>
</svg>
```

### Notes

- Run commands from the repository directory because paths such as `./source`, `./main-image.base64`, and generated SVG files are relative to the current directory.
- SVGs can become much larger than the original file because of Base64 encoding and XML markup.
- This script does not encrypt or authenticate data. Do not use it to protect confidential data.

---

## 中文

`splitfile.sh` 会将文件编码为 Base64，嵌入到一个新生成的 SVG 中；也可以从该 SVG 提取数据并还原文件。请在 Linux、WSL 或其他支持 Bash 的环境中运行。

### 运行要求

- Bash
- GNU `base64`、`split`、`find`、`sort`、`awk`、`tr`，以及 `/dev/urandom`
- 当前工作目录中必须有封面文件 `main-image.base64`

`main-image.base64` 的内容应当是一张 JPG 图片的 Base64 文本。脚本会把它放到 SVG 的第一个 `<image>` 元素中，作为可见封面。

从 JPG 创建封面文件：

```bash
base64 -w 0 cover.jpg > main-image.base64
```

### 使用方法

首次执行时授予脚本可执行权限：

```bash
chmod +x splitfile.sh
```

#### 编码

```bash
./splitfile.sh encode <源文件> [分片大小]
```

脚本会将源文件进行 Base64 编码、切分为多个片段，并将片段写入新 SVG 中的 `<image data="...">` 元素。生成的 SVG 会保存在当前目录，名称为随机的五个英文字母，例如 `AbcDe.svg`。处理期间使用 `./source` 保存临时片段，完成后会删除该目录。

示例：

```bash
./splitfile.sh encode archive.zip
```

当前默认分片大小为 `200k`。GNU `split` 支持 `1K`、`200k`、`2M` 等大小格式，脚本原本计划通过第三个参数设置：

```bash
./splitfile.sh encode archive.zip 1M
```

> 注意：当前脚本中设置第三个参数的条件写反了，因此传入 `1M` 时可能不会生效；不传第三个参数时，默认的 `200k` 可以正常使用。

#### 解码

```bash
./splitfile.sh decode <SVG文件> <输出文件>
```

脚本会按 SVG 文档中的顺序提取所有带有 `data` 属性的 `<image>` 元素，拼接其 Base64 数据后解码到指定输出文件。

示例：

```bash
./splitfile.sh decode AbcDe.svg restored.zip
```

可通过 SHA-256 验证还原结果：

```bash
sha256sum archive.zip restored.zip
```

### 生成的 SVG 结构

生成的 SVG 包含一张可见的 JPG 封面，以及保存文件数据的多个分片：

```xml
<svg ...>
    <rect width="100%" height="100%" fill="white"/>
    <image href="data:image/jpg;base64,..."/>
    <g id="imageGrid">
        <image data="./source/image.000" href="data:image/jpg;base64,..."/>
        <image data="./source/image.001" href="data:image/jpg;base64,..."/>
    </g>
</svg>
```

### 注意事项

- 请从项目目录运行脚本。`./source`、`./main-image.base64` 和生成的 SVG 都是相对于当前目录的路径。
- Base64 编码与 XML 标签会使 SVG 文件明显大于原始文件。
- 本脚本不提供加密或完整性校验，不应将其作为敏感数据的保护手段。
