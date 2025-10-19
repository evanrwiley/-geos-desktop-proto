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
