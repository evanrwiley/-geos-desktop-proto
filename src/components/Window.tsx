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
