#!/usr/bin/env bash

set -o pipefail

SPLIT_SIZE=200k
readonly SOURCE_PATH=./source
readonly BASE64_PATH=./main-image.base64

# svg 文件读取 / base64 插入 svg 文件
encode_svg_base64() {
    [[ -f $BASE64_PATH ]] || {
        printf '错误: 找不到 Base64 文件 %s\n' "$BASE64_PATH" >&2
        exit 1
    }
    # 读取 imageGrid 开始标签之前的 SVG 内容
    local imagebase64
    imagebase64=$(<"$BASE64_PATH")
    [[ -n $imagebase64 ]] || {
        printf '错误: Base64 文件为空\n' >&2
        exit 1
    }

    local svg_header
    svg_header=$(cat <<EOF
<svg id="dev-image-svg" viewBox="0 0 1680 1050" xmlns="http://www.w3.org/2000/svg" style="width:100%;height:auto;display:block;">
    <rect width="100%" height="100%" fill="white"/>
    <image href="data:image/jpg;base64,${imagebase64}"/>
EOF
)
    local svg_body

    # base64 插入 svg 文件
    [[ -d "$SOURCE_PATH" ]] || {
        printf '错误: 找不到目录 %s\n' "$SOURCE_PATH" >&2
        exit 1
    }
    while IFS= read -r -d '' file; do
        payload=$(<"$file")
        svg_body+="        <image data=\"${file}\" href=\"data:image/jpg;base64,${payload}\"/>"$'\n'
    done < <(
    find "$SOURCE_PATH" \
        -maxdepth 1 \
        -type f \
        -name 'image.*' \
        -print0 |
        sort -z
    )

    local svg_content
    local random_name
    random_name=$(LC_ALL=C tr -dc 'A-Za-z' < /dev/urandom | head -c 5)
    printf -v svg_content '%s\n%s\n%s%s\n%s' \
        "${svg_header}" \
        "    <g id=\"imageGrid\">" \
        "${svg_body}" \
        "    </g>" \
        "</svg>"
    printf '%s\n' "$svg_content" > "./$random_name.svg"
}

# svg 文件读取 / base64 提取
decode_svg_base64() {
    # svg 文件读取
    local input_svg=$1
    [[ -f $input_svg ]] || {
        printf '错误: 找不到 SVG 文件 %s\n' "$input_svg" >&2
        return 1
    }

    awk '
    /<image[[:space:]][^>]*data="/ {
        marker = "data:image/jpg;base64,"
        start = index($0, marker)

        if (start > 0) {
            payload = substr($0, start + length(marker))
            sub(/["[:space:]]*\/>[[:space:]]*$/, "", payload)
            printf "%s", payload
            found = 1
        }
    }
    END {
        if (!found) exit 1
    }
    ' "$input_svg" > "./output_base64" || {
        printf '错误: SVG 中未找到有效的数据分片
' >&2
        return 1
    }
}

# ---------------------------------------------------------
# 主程序
# ---------------------------------------------------------
[[ $# -ge 2 ]] || {
    printf '> 用法: %s <encode> <源文件> <split_size: 1K,2M,3k...>\n' "$0" >&2
    printf '> 用法: %s <decode> <svg文件> <output文件.扩展名>\n' "$0" >&2
    exit 2
}

TYPE_CODE=$1
INPUT_FILE=$2

[[ -f $INPUT_FILE ]] || {
    printf '错误: 找不到文件 %s\n' "$INPUT_FILE" >&2
    exit 1
}

case "$1" in
    encode)
        [[ $# -eq 3 ]] || {
            SPLIT_SIZE=$3
        }
        # 1. 临时目录生成
        printf '> svg生成 -> '
        rm -rf "$SOURCE_PATH"
        mkdir -p "$SOURCE_PATH"
        # 2. base64转换 / split分割
        printf 'split分割 -> '
        base64 -w 0 "$INPUT_FILE" | 
            split -b "$SPLIT_SIZE" -d -a 3 - "$SOURCE_PATH/image."
        # 3. svg 文件读取 / base64 插入 svg 文件
        printf 'svg处理 -> '
        encode_svg_base64
        # 4. 临时文件清理
        printf '清理临时文件\n'
        rm -r "$SOURCE_PATH"
        ;;
    decode)
        [[ $# -eq 3 ]] || {
            printf '用法: %s decode <svg文件> <输出文件>\n' "$0" >&2
            exit 2
        }
        output_file=$3
        printf '> svg还原 -> '
        # 1. svg 文件读取 / base64 提取
        printf 'svg处理 -> '
        decode_svg_base64 "$2" || exit 1
        # 2. base64 解码
        printf 'base64 解码 -> '
        base64 -d "./output_base64" > "$output_file" || {
            printf '错误: Base64 解码失败' >&2
            rm -f -- "$output_file"
            exit 1
        }
        # 3. 临时文件清理
        printf '清理临时文件\n'
        rm ./output_base64
        ;;
    *)
        printf '未知操作类型 %s\n' "$1" >&2
        exit 2
        ;;
esac
