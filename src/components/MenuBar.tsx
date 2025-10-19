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
