<#
.SYNOPSIS
Create GEOS desktop prototype scaffold, init git, and push to GitHub.

.PARAMETER Repo
Full repo path on GitHub (owner/repo). Example: evanrwiley/geos-desktop-proto
If your repo name contains a leading hyphen use the exact name as created on GitHub.

.PARAMETER LocalPath
Local directory to create files in (default: current directory).

.PARAMETER UseSsh
Switch: use SSH remote URL (git@github.com:owner/repo.git). Default is HTTPS.

.PARAMETER UseGh
Switch: use gh CLI to create the repository and push (requires gh logged in).

.EXAMPLE
.\setup-geos-repo.ps1 -Repo "evanrwiley/-geos-desktop-proto" -UseSsh
#>

param(
  [Parameter(Mandatory=$true)][string]$Repo,
  [string]$LocalPath = ".",
  [switch]$UseSsh,
  [switch]$UseGh
)

function Write-Header($msg) {
  Write-Host "=== $msg ===" -ForegroundColor Cyan
}

# Resolve local path
$fullPath = (Resolve-Path -Path $LocalPath).Path
Write-Header "Using project folder: $fullPath"

# Create directories
$dirs = @("$fullPath\src", "$fullPath\src\context", "$fullPath\src\components")
foreach ($d in $dirs) {
  if (-not (Test-Path $d)) {
    New-Item -ItemType Directory -Path $d | Out-Null
    Write-Host "Created $d"
  }
}

# Helper to write files with UTF8 (no BOM)
function Write-File($path, $content) {
  $dir = Split-Path -Parent $path
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $content | Out-File -FilePath $path -Encoding utf8 -Force
  Write-Host "Wrote $path"
}

# Files content (single-quoted here-strings to avoid variable interpolation)
$files = @{
  "package.json" = @'
{
  "name": "geos-desktop-proto",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "vite": "^5.0.0",
    "typescript": "^5.2.2",
    "@types/react": "^18.2.28",
    "@types/react-dom": "^18.2.11"
  }
}
'@

  "tsconfig.json" = @'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["DOM","ES2020"],
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowJs": false,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "module": "ESNext",
    "moduleResolution": "Node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx"
  },
  "include": ["src"]
}
'@

  "index.html" = @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1.0" />
    <title>GEOS Desktop Prototype</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
'@

  "src/main.tsx" = @'
import React from "react"
import { createRoot } from "react-dom/client"
import App from "./App"
import "./styles.css"

createRoot(document.getElementById("root")!).render(<App />)
'@

  "src/App.tsx" = @'
import React from "react"
import { FileSystemProvider } from "./context/FileSystem"
import Desktop from "./components/Desktop"

export default function App() {
  return (
    <FileSystemProvider>
      <Desktop />
    </FileSystemProvider>
  )
}
'@

  "src/context/FileSystem.tsx" = @'
import React, { createContext, useContext, useState } from "react"

export type FileItem = {
  id: string
  name: string
  type: "thread" | "text" | "app" | "folder"
  content?: string
  meta?: Record<string, any>
}

type FSContext = {
  files: FileItem[]
  openFile: (id: string) => FileItem | undefined
  listFiles: () => FileItem[]
  createFile: (file: FileItem) => void
}

const FS = createContext<FSContext | null>(null)

const initial: FileItem[] = [
  { id: "1", name: "Welcome.thread", type: "thread", content: "Welcome to the BBS — this is the first post." },
  { id: "2", name: "General.thread", type: "thread", content: "General discussion board." },
  { id: "3", name: "Notes.txt", type: "text", content: "Local notes file." }
]

export const FileSystemProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [files, setFiles] = useState<FileItem[]>(initial)

  const openFile = (id: string) => files.find(f => f.id === id)
  const listFiles = () => files
  const createFile = (file: FileItem) => setFiles(s => [...s, file])

  return <FS.Provider value={{ files, openFile, listFiles, createFile }}>{children}</FS.Provider>
}

export const useFS = () => {
  const ctx = useContext(FS)
  if (!ctx) throw new Error("useFS must be used inside FileSystemProvider")
  return ctx
}
'@

  "src/components/Desktop.tsx" = @'
import React, { useState } from "react"
import { useFS } from "../context/FileSystem"
import Window from "./Window"
import FileManager from "./FileManager"
import MenuBar from "./MenuBar"

type AppInstance = {
  id: string
  title: string
  content: React.ReactNode
  z: number
}

export default function Desktop() {
  const { listFiles } = useFS()
  const [apps, setApps] = useState<AppInstance[]>([])
  const [zCounter, setZCounter] = useState(1)

  const openApp = (title: string, content: React.ReactNode) => {
    const id = String(Math.random())
    const nextZ = zCounter + 1
    setApps(a => [...a, { id, title, content, z: nextZ }])
    setZCounter(nextZ)
  }

  const openFileAsWindow = (fileId: string) => {
    const file = listFiles().find(f => f.id === fileId)
    if (!file) return
    openApp(file.name, <div style={{ padding: 8, whiteSpace: "pre-wrap" }}>{file.content}</div>)
  }

  const closeApp = (id: string) => setApps(a => a.filter(x => x.id !== id))
  const focusApp = (id: string) =>
    setApps(a =>
      a.map(app => {
        if (app.id === id) {
          const nextZ = zCounter + 1
          setZCounter(nextZ)
          return { ...app, z: nextZ }
        }
        return app
      })
    )

  return (
    <div className="desktop">
      <MenuBar onOpenApp={() => openApp("File Manager", <FileManager onOpenFile={openFileAsWindow} />)} />
      <div className="wallpaper">
        <div className="icon-grid">
          {listFiles().map(f => (
            <div key={f.id} className="icon" onDoubleClick={() => openFileAsWindow(f.id)}>
              <div className="icon-image">{f.type === "thread" ? "✉️" : f.type === "app" ? "🧭" : "📄"}</div>
              <div className="icon-label">{f.name}</div>
            </div>
          ))}
        </div>
      </div>

      {apps.map(app => (
        <Window
          key={app.id}
          title={app.title}
          zIndex={app.z}
          onClose={() => closeApp(app.id)}
          onFocus={() => focusApp(app.id)}
        >
          {app.content}
        </Window>
      ))}

      <div className="taskbar">
        {apps.map(a => (
          <button key={a.id} className="task-button" onClick={() => focusApp(a.id)}>
            {a.title}
          </button>
        ))}
        <div style={{ marginLeft: "auto", color: "#cfe" }}>12:00</div>
      </div>
    </div>
  )
}
'@

  "src/components/Window.tsx" = @'
import React, { useRef, useState } from "react"

type Props = {
  title: string
  children?: React.ReactNode
  onClose?: () => void
  onFocus?: () => void
  zIndex?: number
}

export default function Window({ title, children, onClose, onFocus, zIndex = 1 }: Props) {
  const winRef = useRef<HTMLDivElement | null>(null)
  const [pos, setPos] = useState({ x: 100, y: 80 })
  const [size] = useState({ w: 420, h: 300 })
  const dragging = useRef(false)
  const dragStart = useRef({ x: 0, y: 0 })

  const onMouseDownTitle = (e: React.MouseEvent) => {
    dragging.current = true
    dragStart.current = { x: e.clientX - pos.x, y: e.clientY - pos.y }
    onFocus && onFocus()
  }
  const onMouseMove = (e: MouseEvent) => {
    if (!dragging.current) return
    setPos({ x: e.clientX - dragStart.current.x, y: e.clientY - dragStart.current.y })
  }
  const onMouseUp = () => (dragging.current = false)

  React.useEffect(() => {
    window.addEventListener("mousemove", onMouseMove)
    window.addEventListener("mouseup", onMouseUp)
    return () => {
      window.removeEventListener("mousemove", onMouseMove)
      window.removeEventListener("mouseup", onMouseUp)
    }
  }, [])

  return (
    <div
      ref={winRef}
      className="window"
      style={{ transform: `translate(${pos.x}px, ${pos.y}px)`, width: size.w, height: size.h, zIndex }}
      onMouseDown={onFocus}
    >
      <div className="titlebar" onMouseDown={onMouseDownTitle}>
        <div className="title">{title}</div>
        <div className="controls">
          <button onClick={onClose} aria-label="Close">✕</button>
        </div>
      </div>
      <div className="window-content">{children}</div>
    </div>
  )
}
'@

  "src/components/FileManager.tsx" = @'
import React from "react"
import { useFS } from "../context/FileSystem"

export default function FileManager({ onOpenFile }: { onOpenFile?: (id: string) => void }) {
  const { listFiles } = useFS()
  const files = listFiles()

  return (
    <div style={{ padding: 8, height: "100%", boxSizing: "border-box" }}>
      <h3>File Manager</h3>
      <ul className="file-list" role="list">
        {files.map(f => (
          <li key={f.id} onDoubleClick={() => onOpenFile && onOpenFile(f.id)}>
            <span className="file-type">{f.type === "thread" ? "✉️" : "📄"}</span>
            <span className="file-name">{f.name}</span>
          </li>
        ))}
      </ul>
    </div>
  )
}
'@

  "src/components/MenuBar.tsx" = @'
import React from "react"

export default function MenuBar({ onOpenApp }: { onOpenApp?: () => void }) {
  return (
    <div className="menubar" role="menubar">
      <div className="menu" role="menuitem">File
        <div className="menu-dropdown">
          <button onClick={onOpenApp}>Open File Manager</button>
          <button>Logout</button>
        </div>
      </div>
      <div className="menu" role="menuitem">Edit
        <div className="menu-dropdown"><button>Copy</button><button>Paste</button></div>
      </div>
      <div className="menu" role="menuitem">View
        <div className="menu-dropdown"><button>Toggle Grid</button></div>
      </div>
    </div>
  )
}
'@

  "src/styles.css" = @'
:root{
  --bg:#0b1a2a;
  --panel:#cfd8e3;
  --accent:#2b7cff;
  --title:#ffffff;
  --retro-font: "Press Start 2P", monospace;
}

/* Basic retro-ish look; swap fonts/palettes for GEOS authenticity */
body,html,#root{height:100%;margin:0;font-family:var(--retro-font);background:var(--bg);color:var(--title)}
.desktop{position:relative;height:100vh;overflow:hidden}
.menubar{display:flex;gap:12px;padding:6px 8px;background:#0d2a44;color:var(--panel);align-items:center}
.menu{position:relative;padding:4px}
.menu-dropdown{display:none;position:absolute;top:100%;left:0;background:#dfe8f3;border:2px solid #102020;padding:6px}
.menu:hover .menu-dropdown{display:block}
.wallpaper{height:calc(100% - 40px);background:linear-gradient(180deg,#0b2a44,#061426);padding:12px;box-sizing:border-box}
.icon-grid{display:flex;flex-wrap:wrap;gap:12px}
.icon{width:90px;text-align:center;color:var(--panel);cursor:default;user-select:none}
.icon-image{font-size:28px}
.icon-label{font-size:12px;margin-top:6px}
.taskbar{position:absolute;bottom:0;left:0;right:0;height:36px;background:#091a30;display:flex;align-items:center;padding:0 8px;gap:6px}
.task-button{background:#1b3a60;color:var(--panel);border:2px inset #12324a;padding:4px 8px;cursor:pointer;font-size:12px}

/* Window chrome */
.window{position:absolute;border:4px solid #c0c0c0;background:#e6eef8;box-shadow:4px 4px 0 rgba(0,0,0,0.4);overflow:hidden}
.titlebar{background:#1b3a60;color:var(--panel);display:flex;justify-content:space-between;align-items:center;padding:4px 8px;cursor:move}
.title{font-size:12px}
.controls button{background:#f64;border:0;color:white;padding:2px 6px}
.window-content{background:white;height:calc(100% - 32px);overflow:auto;padding:6px}
.file-list{list-style:none;margin:0;padding:0}
.file-list li{padding:6px;border-bottom:1px solid #eee;display:flex;gap:8px;align-items:center;cursor:pointer}
.file-list li:hover{background:#f6f9ff}
'@

  "README.md" = @'
# GEOS Desktop Prototype

This is a minimal GEOS-style desktop prototype built with React + TypeScript + Vite.
It demonstrates a desktop, menu bar, taskbar, draggable windows, and a simple file manager where "threads" are files.

Quick start
1. Install dependencies
   npm install

2. Start dev server
   npm run dev

3. Open http://localhost:5173 in your browser

Files included
- src/components/* - Desktop shell, Window, FileManager, MenuBar
- src/context/FileSystem.tsx - simple in-memory filesystem provider
- src/styles.css - retro-ish styles (swap fonts and palettes for more authenticity)

Open in VS Code
- In your terminal:
  code .

Create a GitHub repo and push (example)
1. Create a repo on GitHub (via website or `gh repo create`).
2. Then run:
   git init
   git add .
   git commit -m "Initial GEOS desktop prototype"
   git branch -M main
   git remote add origin git@github.com:evanrwiley/geos-desktop-proto.git
   git push -u origin main

Optional next steps
- Replace the UI font with a Commodore/GEOS font file.
- Add Howler.js for system sounds.
- Swap the in-memory FS for an IndexedDB-backed adapter.
- Integrate a forum/BBS API and map threads to .thread files.

If you want, I can also:
- Prepare a ZIP of this scaffold for download (I can't host it directly from here).
- Provide exact GitHub CLI commands to create the repo from your machine.
- Add more apps (Reader, GeoWrite compose window) in the code and paste them here.
'@

  ".gitignore" = @'
/node_modules
/dist
/.turbo
/.env
.vscode
'@
}

# Write files
foreach ($kv in $files.GetEnumerator()) {
  $path = Join-Path -Path $fullPath -ChildPath $kv.Key
  Write-File -path $path -content $kv.Value
}

# Change to project directory
Set-Location -Path $fullPath

# Check for git
$gitExists = (Get-Command git -ErrorAction SilentlyContinue) -ne $null
if (-not $gitExists) {
  Write-Warning "git not found in PATH. Install git and re-run the script to push to GitHub."
  exit 0
}

# Initialize git if needed
$insideGit = $false
try {
  $insideGit = git rev-parse --is-inside-work-tree 2>$null
} catch {}
if (-not $insideGit) {
  git init
  Write-Host "Initialized new git repository."
}

# Add and commit
git add .
try {
  git commit -m "Add scaffold files for GEOS desktop prototype" -q
  Write-Host "Committed files."
} catch {
  Write-Host "Nothing to commit or commit failed (maybe initial package.json already present). Continuing..."
}

# Create remote via gh if requested
if ($UseGh) {
  $ghExists = (Get-Command gh -ErrorAction SilentlyContinue) -ne $null
  if (-not $ghExists) {
    Write-Warning "gh CLI not found. Install GitHub CLI (gh) or run without -UseGh."
  } else {
    Write-Host "Creating remote repo using gh..."
    try {
      # gh repo create requires a repo name without owner if creating under current user,
      # but it accepts full name for org/owner. We'll attempt to create the repo using full path.
      gh repo create $Repo --public --source="$fullPath" --remote=origin --push
      Write-Host "gh created repo and pushed."
      exit 0
    } catch {
      Write-Warning "gh repo create failed: $($_.Exception.Message). Will attempt to set remote and push manually."
    }
  }
}

# Set remote origin (SSH or HTTPS)
if ($UseSsh) {
  $remoteUrl = "git@github.com:$Repo.git"
} else {
  $remoteUrl = "https://github.com/$Repo.git"
}

# Set or update remote
$existingRemote = $null
try {
  $existingRemote = git remote get-url origin 2>$null
} catch {}
if ($existingRemote) {
  Write-Host "Existing origin is: $existingRemote"
  if ($existingRemote -ne $remoteUrl) {
    Write-Host "Updating origin to $remoteUrl"
    git remote set-url origin $remoteUrl
  } else {
    Write-Host "Origin remote already matches $remoteUrl"
  }
} else {
  git remote add origin $remoteUrl
  Write-Host "Added origin $remoteUrl"
}

# Ensure branch main
git branch -M main

# Push
Write-Host "Pushing to origin main..."
try {
  git push -u origin main
  Write-Host "Push succeeded."
} catch {
  Write-Warning "Push failed: $($_.Exception.Message)"
  Write-Host "If authentication failed, ensure your SSH key or git credentials are set up and try:"
  Write-Host "  git push -u origin main"
}

Write-Header "Done - scaffold created"
Write-Host "Open the folder in VS Code: code $fullPath"
Write-Host "Run npm install && npm run dev to start the dev server."
