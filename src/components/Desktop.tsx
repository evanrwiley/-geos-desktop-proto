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
