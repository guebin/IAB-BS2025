#!/bin/bash

echo "📚 Building and publishing Quarto project with both HTML and Reveal.js formats..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf docs/ .quarto

# Use start.sh approach - render individual files
echo "🌐 Rendering index.qmd..."
quarto render index.qmd --to html

# Check if index build was successful
if [ $? -ne 0 ]; then
    echo "❌ Index build failed!"
    exit 1
fi

# Render posts
echo "📊 Rendering posts..."
cd posts

for file in *.ipynb *.qmd; do
    if [ -f "$file" ]; then
        filename=$(basename "$file" | sed 's/\.[^.]*$//')
        echo "   📄 Processing $filename..."
        
        # Render HTML version first
        quarto render "$file" --to html
        
        # Check if render was successful
        if [ $? -ne 0 ]; then
            echo "❌ Failed to render $filename"
            cd ..
            exit 1
        fi
        
        # Save the HTML version with a temporary name to protect it
        if [ -f "../docs/posts/$filename.html" ]; then
            cp "../docs/posts/$filename.html" "../docs/posts/$filename-temp.html"
        fi
        
        # Also backup the HTML figure files if they exist
        if [ -d "../docs/posts/${filename}_files/figure-html" ]; then
            cp -r "../docs/posts/${filename}_files/figure-html" "../docs/posts/${filename}_files/figure-html-backup"
        fi
        
        # Render Reveal.js version  
        quarto render "$file" --to revealjs
        
        # Check if render was successful  
        if [ $? -ne 0 ]; then
            echo "❌ Failed to render $filename slides"
            cd ..
            exit 1
        fi
        
        # Now we have revealjs in $filename.html, move it to slides version
        if [ -f "../docs/posts/$filename.html" ]; then
            mv "../docs/posts/$filename.html" "../docs/posts/$filename-slides.html"
        fi
        
        # Restore the original HTML version
        if [ -f "../docs/posts/$filename-temp.html" ]; then
            mv "../docs/posts/$filename-temp.html" "../docs/posts/$filename.html"
        fi
        
        # Restore the HTML figure files if they were backed up
        if [ -d "../docs/posts/${filename}_files/figure-html-backup" ]; then
            mv "../docs/posts/${filename}_files/figure-html-backup" "../docs/posts/${filename}_files/figure-html"
        fi
        
        # If no HTML figure directory exists but revealjs figure directory does, copy it
        if [ ! -d "../docs/posts/${filename}_files/figure-html" ] && [ -d "../docs/posts/${filename}_files/figure-revealjs" ]; then
            cp -r "../docs/posts/${filename}_files/figure-revealjs" "../docs/posts/${filename}_files/figure-html"
        fi
    fi
done

cd ..

# Create docs directory and copy files
echo "📁 Creating docs folder and copying files..."
mkdir -p docs/posts

# Copy main files
if [ -f "_site/index.html" ]; then
    cp _site/index.html docs/
elif [ -f "index.html" ]; then
    cp index.html docs/
fi

# Copy posts
for file in posts/*.html; do
    if [ -f "$file" ]; then
        cp "$file" docs/posts/
    fi
done

# Copy site_libs and assets
if [ -d "_site/site_libs" ]; then
    cp -r _site/site_libs docs/
elif [ -d "site_libs" ]; then
    cp -r site_libs docs/
fi

if [ -d "_site" ]; then
    # Copy everything from _site
    cp -r _site/* docs/ 2>/dev/null || true
fi

# Copy additional assets
for asset in styles.css profile.jpg fonts; do
    if [ -e "$asset" ]; then
        cp -r "$asset" docs/
    fi
done


echo "✅ Project build completed successfully"

# Check if we're in a git repository and commit if requested
if [ -d ".git" ]; then
    echo "📤 Git repository detected. Checking status..."
    
    # Check if there are changes to commit
    if [ -n "$(git status --porcelain)" ]; then
        echo "📝 Changes detected. Adding files to git..."
        git add docs/
        
        # Commit with timestamp
        commit_message="Update site: $(date '+%Y-%m-%d %H:%M:%S')"
        git commit -m "$commit_message"
        echo "✅ Changes committed: $commit_message"
        
        # Push to remote repository
        echo "🚀 Pushing to remote repository..."
        git push
        if [ $? -eq 0 ]; then
            echo "✅ Successfully pushed to remote repository"
        else
            echo "❌ Failed to push to remote repository"
        fi
    else
        echo "ℹ️  No changes to commit"
    fi
fi

# Clean up temporary files
echo "🧹 Cleaning up..."
rm -f _quarto.yml.bak _quarto.yml.bak2 index.html

echo ""
echo "🎉 Build completed successfully!"
echo "📄 HTML site: docs/index.html"
echo "🎯 Slides: docs/slides/index.html"
echo ""
echo "To serve locally:"
echo "  cd docs && python3 -m http.server 8000"
echo "  Then visit: http://localhost:8000"