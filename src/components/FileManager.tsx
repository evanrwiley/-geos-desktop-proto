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
