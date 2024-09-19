#!/bin/bash

# Check if project name is provided
if [ $# -eq 0 ]; then
    echo "Please provide a project name"
    exit 1
fi

PROJECT_NAME=$1

# Create project using Vite
npm create vite@latest $PROJECT_NAME -- --template svelte-ts

# Navigate to project directory
cd $PROJECT_NAME

# Install dependencies
npm install

# Add Tailwind CSS
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# Configure Tailwind CSS
cat > tailwind.config.js << EOL
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOL

# Update src/main.ts to import Tailwind CSS
# sed -i '' '1s/^/import ".\/app.css"\n/' src/main.ts

# add tailwindcss to the top of the file
sed -i '' '1s/^/@tailwind base;\n/' src/app.css
sed -i '' '1s/^/@tailwind components;\n/' src/app.css
sed -i '' '1s/^/@tailwind utilities;\n/' src/app.css

# Install shadcn-svelte dependencies
npm install -D @sveltejs/vite-plugin-svelte svelte-preprocess @types/node

# Update vite.config.ts
cat > vite.config.ts << EOL
import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import { fileURLToPath, URL } from 'node:url'
import { readFileSync } from "node:fs";

const file = fileURLToPath(new URL('package.json', import.meta.url));
const json = readFileSync(file, 'utf8');
const pkg = JSON.parse(json);

export default defineConfig({
	define: {
		__DATE__: \`'\${new Date().toISOString()}'\`,
		__RELOAD_SW__: false,
		'process.env.NODE_ENV': process.env.NODE_ENV === 'production' ? '"production"' : '"development"',
		'__APP_VERSION__': JSON.stringify(pkg.version),
		'__APP_NAME__': JSON.stringify(pkg.name),
		'__APP_HOMEPAGE__': JSON.stringify(pkg.homepage),
		'__APP_DESCRIPTION__': JSON.stringify(pkg.description),
		'__APP_MENU_TITLE__': JSON.stringify(pkg.menu_title),
		'__APP_MENU_SUBTITLE__': JSON.stringify(pkg.menu_subtitle),
		'__APP_PROFILE_TABLE__': JSON.stringify(pkg.profileTable),
		'__APP_PROFILE_KEY__': JSON.stringify(pkg.profileKey),
		'__APP_THEME_COLOR__': JSON.stringify(pkg.theme_color),
		'__APP_BACKGROUND_COLOR__': JSON.stringify(pkg.background_color),	  
	},
  plugins: [svelte()],
  resolve: {
    alias: {
      \$lib: fileURLToPath(new URL('./src/lib', import.meta.url)),
    }
  }
})
EOL

# Update tsconfig.json
cat > tsconfig.json << EOL
{
  "extends": "@tsconfig/svelte/tsconfig.json",
  "compilerOptions": {
    "target": "ESNext",
    "useDefineForClassFields": true,
    "module": "ESNext",
    "resolveJsonModule": true,
    "allowJs": true,
    "checkJs": true,
    "isolatedModules": true,
    "baseUrl": ".",
    "paths": {
      "\$lib": ["src/lib"],
      "\$lib/*": ["src/lib/*"]
    }
  },
  "include": ["src/**/*.d.ts", "src/**/*.ts", "src/**/*.js", "src/**/*.svelte"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOL

# Install shadcn-svelte and its dependencies
npm install -D shadcn-svelte class-variance-authority clsx tailwind-merge lucide-svelte tailwind-variants

# Create components.json for shadcn-svelte
cat > components.json << EOL
{
  "\$schema": "https://shadcn-svelte.com/schema.json",
  "style": "default",
  "tailwind": {
    "config": "tailwind.config.js",
    "css": "src/app.css",
    "baseColor": "slate"
  },
  "aliases": {
    "components": "\$lib/components",
    "utils": "\$lib/utils"
  }
}
EOL


cat > src/app.d.ts << EOL
// See https://kit.svelte.dev/docs/types#app
// for information about these interfaces
// and what to do when importing types
declare namespace App {
	// interface Locals {}
	// interface PageData {}
	// interface Error {}
	// interface Platform {}
}
declare const __APP_VERSION__: string
declare const __APP_NAME__: string
declare const __APP_HOMEPAGE__: string
declare const __APP_DESCRIPTION__: string
declare const __APP_MENU_TITLE__: string
declare const __APP_MENU_SUBTITLE__: string
declare const __APP_PROFILE_TABLE__: string
declare const __APP_PROFILE_KEY__: string
declare const __APP_THEME_COLOR__: string
declare const __APP_BACKGROUND_COLOR__: string
EOL



# Create necessary directories
mkdir -p src/lib/components src/lib/utils

# Add utility function
cat > src/lib/utils/cn.ts << EOL
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
EOL

# Create utils.js to re-export from utils/cn.ts
cat > src/lib/utils.js << EOL
export * from './utils/cn'
EOL

# Add a sample button component
npx shadcn-svelte add button -y

# Update App.svelte with a sample button
cat > src/App.svelte << EOL
<script lang="ts">
import { Button } from "\$lib/components/ui/button";
let counter = \$state(0)
const app_version = __APP_VERSION__
const app_name = __APP_NAME__
</script>

<main class="container mx-auto p-4">
  <h1 class="text-3xl font-bold mb-4">Welcome to Svelte5 with shadcn-svelte</h1>
  <Button onclick={()=>counter++}>Click me</Button>
  <br/>Counter: {counter}
  <br/>
  <p class="text-sm text-gray-500 mt-4">App version: {app_version}</p>
  <p class="text-sm text-gray-500">App name: {app_name}</p>
</main>
EOL

# Create dev.sh script
cat > dev.sh << EOL
npm run dev -- --open
EOL
chmod +x dev.sh

echo "svelte5 upgrade"
npm install svelte@next
npm install @sveltejs/vite-plugin-svelte@next

# Update src/main.ts to import { mount }
sed -i '' '1s/^/import { mount } from "svelte";\n/' src/main.ts
sed -i '' 's/new App({/mount(App, {/' src/main.ts

# apply changes to package.json to override the svelte dependency
sed '
/^  "dependencies": {/,/^  }$/ {
  /^  }$/ {
    s#^  }#  },\
  "overrides": {\
    "@melt-ui\/svelte": {\
      "svelte": "^5.0.0-next.251"\
    }\
  }#
  }
}
' package.json > package_new.json
cp package_new.json package.json
rm package_new.json

# setup shadcn-svelte
npx shadcn-svelte@latest init

echo "Project setup complete."
echo "Now run:"
echo ""
echo "cd $PROJECT_NAME"
echo "./dev.sh'"
