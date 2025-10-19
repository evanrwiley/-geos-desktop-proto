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
