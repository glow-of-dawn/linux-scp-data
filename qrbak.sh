#!/usr/bin/env bash

set -euo pipefail

readonly QR_VERSION=15
readonly QR_SIZE=6
readonly QR_MARGIN=4
readonly CHUNK_BYTES=260
readonly QR_PIXELS=$(((17 + 4 * QR_VERSION + 2 * QR_MARGIN) * QR_SIZE))

usage() {
    cat <<'EOF'
用法:
  ./qrbak.sh encode <输入文件> <输出图片.png>
  ./qrbak.sh decode <输入图片.png> <输出文件>

依赖: qrencode, zbarimg, ImageMagick (montage, convert, identify)
EOF
}

require_commands() {
    local command_name
    for command_name in qrencode zbarimg montage convert identify; do
        command -v "$command_name" >/dev/null || {
            printf '错误: 未安装命令 %s\n' "$command_name" >&2
            exit 1
        }
    done
}

encode() {
    local input_path=$1 output_path=$2 work_dir file_hash total_chunks columns
    local chunk_path chunk_index payload qr_path

    [[ -f $input_path ]] || { printf '错误: 找不到输入文件 %s\n' "$input_path" >&2; exit 1; }
    work_dir=$(mktemp -d)
    trap 'rm -rf "$work_dir"' RETURN

    split -b "$CHUNK_BYTES" -d -a 6 -- "$input_path" "$work_dir/chunk-"
    total_chunks=$(find "$work_dir" -maxdepth 1 -name 'chunk-*' -type f | wc -l)
    (( total_chunks > 0 )) || { printf '错误: 输入文件为空，无法生成二维码。\n' >&2; exit 1; }
    (( total_chunks <= 999999 )) || { printf '错误: 文件过大，数据块数量超过 999999。\n' >&2; exit 1; }

    file_hash=$(sha256sum "$input_path" | cut -c1-16)
    printf '读取 %s，切分为 %s 个数据块。\n' "$input_path" "$total_chunks"

    for chunk_path in "$work_dir"/chunk-*; do
        chunk_index=${chunk_path##*-}
        payload=$(printf '%s|%06d|%06d|' "$file_hash" "$((10#$chunk_index))" "$total_chunks")
        payload+=$(base64 -w 0 -- "$chunk_path")
        qr_path="$work_dir/qr-${chunk_index}.png"
        printf '%s' "$payload" | qrencode -8 -v "$QR_VERSION" -l M \
            -s "$QR_SIZE" -m "$QR_MARGIN" -o "$qr_path"
    done

    columns=$(awk -v total="$total_chunks" 'BEGIN { print int(sqrt(total - 1)) + 1 }')
    montage "$work_dir"/qr-*.png -tile "${columns}x" -geometry +0+0 -background white "$output_path"
    printf '已生成二维码拼图: %s\n' "$output_path"
}

decode() {
    local input_path=$1 output_path=$2 work_dir dimensions width height columns rows
    local crop_path content file_hash index total encoded_data
    local expected_hash expected_total
    declare -A chunks

    [[ -f $input_path ]] || { printf '错误: 找不到输入图片 %s\n' "$input_path" >&2; exit 1; }
    work_dir=$(mktemp -d)
    trap 'rm -rf "$work_dir"' RETURN

    dimensions=$(identify -format '%w %h' -- "$input_path")
    read -r width height <<< "$dimensions"
    (( width % QR_PIXELS == 0 && height % QR_PIXELS == 0 )) || {
        printf '错误: 图片尺寸不是预期二维码尺寸 %spx 的整数倍。\n' "$QR_PIXELS" >&2
        exit 1
    }
    columns=$((width / QR_PIXELS))
    rows=$((height / QR_PIXELS))
    printf '解析 %s 行 x %s 列二维码拼图。\n' "$rows" "$columns"

    convert "$input_path" -crop "${QR_PIXELS}x${QR_PIXELS}" +repage "$work_dir/crop.png"
    for crop_path in "$work_dir"/crop-*.png; do
        content=$(zbarimg --quiet --raw "$crop_path" 2>/dev/null || true)
        [[ -n $content ]] || continue
        IFS='|' read -r file_hash index total encoded_data <<< "$content"
        [[ $file_hash =~ ^[0-9a-f]{16}$ && $index =~ ^[0-9]{6}$ && $total =~ ^[0-9]{6}$ && -n $encoded_data ]] || continue
        if [[ -z ${expected_hash:-} ]]; then
            expected_hash=$file_hash
            expected_total=$((10#$total))
        fi
        [[ $file_hash == "$expected_hash" && $((10#$total)) -eq "$expected_total" ]] || {
            printf '错误: 二维码来自不同的拼图，拒绝还原。\n' >&2
            exit 1
        }
        chunks[$((10#$index))]=$encoded_data
    done

    [[ -n ${expected_total:-} ]] || { printf '错误: 未识别到有效二维码。\n' >&2; exit 1; }
    for ((index = 0; index < expected_total; index++)); do
        [[ -n ${chunks[$index]:-} ]] || { printf '错误: 缺少第 %s 个数据块。\n' "$index" >&2; exit 1; }
        printf '%s' "${chunks[$index]}" | base64 -d >> "$work_dir/restored"
    done

    [[ $(sha256sum "$work_dir/restored" | cut -c1-16) == "$expected_hash" ]] || {
        printf '错误: 校验和不匹配，已拒绝写入输出文件。\n' >&2
        exit 1
    }
    mv -- "$work_dir/restored" "$output_path"
    printf '已还原 %s 个数据块至: %s\n' "$expected_total" "$output_path"
}

[[ $# -eq 3 ]] || { usage >&2; exit 2; }
require_commands
case $1 in
    encode) encode "$2" "$3" ;;
    decode) decode "$2" "$3" ;;
    *) usage >&2; exit 2 ;;
esac