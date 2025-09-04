#!/bin/bash

echo "📚 Quarto 개발 서버 시작"
echo "=============================="

# 기존 프로세스 정리
echo "🧹 기존 Quarto 프로세스 정리..."
pkill -f "quarto preview" >/dev/null 2>&1 || true
sleep 1

# 캐시 정리
echo "🗂️ 캐시 정리..."
rm -rf .quarto _site docs >/dev/null 2>&1 || true

echo ""
echo "미리보기 방식을 선택하세요:"
echo "1) 🌐 HTML 웹사이트 (전체 프로젝트)"  
echo "2) 📊 Reveal.js 슬라이드 (posts 중 선택)"
echo "3) 🚪 종료"
echo ""
read -p "선택하세요 (1-3): " choice

case "$choice" in
    "1")
        echo ""
        echo "🌐 HTML 웹사이트 미리보기 시작..."
        echo "🚀 미리보기 서버 시작 (초기 렌더링은 자동으로 수행됩니다)..."
        echo "👀 브라우저가 자동으로 열리지 않으면 http://localhost:4200 를 방문하세요"
        echo ""
        
        # Quarto preview 시작 (자동 리로드 포함)
        quarto preview --port 4200 --host 127.0.0.1
        ;;
        
    "2")
        echo ""
        echo "📊 Reveal.js 슬라이드 미리보기"
        
        # posts 폴더의 파일 목록 표시
        if [ -d "posts" ]; then
            echo "사용 가능한 파일:"
            files=(posts/*.ipynb posts/*.qmd)
            valid_files=()
            
            for file in "${files[@]}"; do
                if [ -f "$file" ]; then
                    basename_file=$(basename "$file")
                    valid_files+=("$file")
                    echo "  ${#valid_files[@]}) $basename_file"
                fi
            done
            
            if [ ${#valid_files[@]} -eq 0 ]; then
                echo "❌ posts 폴더에서 .ipynb 또는 .qmd 파일을 찾을 수 없습니다."
                exit 1
            fi
            
            echo ""
            read -p "파일 번호를 선택하세요 (1-${#valid_files[@]}): " file_choice
            
            # 입력 검증
            if [[ "$file_choice" =~ ^[0-9]+$ ]] && [ "$file_choice" -ge 1 ] && [ "$file_choice" -le ${#valid_files[@]} ]; then
                selected_file=${valid_files[$((file_choice-1))]}
                filename=$(basename "$selected_file")
                
                echo ""
                echo "📊 $filename Reveal.js 슬라이드 미리보기 시작..."
                echo "🚀 미리보기 서버 시작..."
                echo "👀 브라우저가 자동으로 열리지 않으면 http://localhost:4200 를 방문하세요"
                echo ""
                
                cd posts
                quarto preview "$filename" --to revealjs --port 4201 --host 127.0.0.1
            else
                echo "❌ 잘못된 선택입니다."
                exit 1
            fi
        else
            echo "❌ posts 폴더를 찾을 수 없습니다."
            exit 1
        fi
        ;;
        
    "3")
        echo "👋 미리보기를 종료합니다."
        exit 0
        ;;
        
    *)
        echo "❌ 잘못된 선택입니다. 1, 2, 또는 3을 선택해주세요."
        exit 1
        ;;
esac