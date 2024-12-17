import { Graph, Node } from "@antv/x6";

declare global {
  interface Window {
    handleFlutterMessage: (message: string) => void;
    onNodeMoved?: (data: {
      id: string;
      position: { x: number; y: number };
    }) => void;
    initGraph: (containerId: string) => Promise<void>;
    addNode: (nodeData: NodeData) => any;
    addEdge: (edgeData: EdgeData) => any;
    chrome?: {
      webview: {
        postMessage: (message: string) => void;
      };
    };
  }
}

// 初始化图形实例
let graph: Graph | null = null;

interface NodeData {
  id: string;
  x: number;
  y: number;
  width?: number;
  height?: number;
  label: string;
}

interface EdgeData {
  source: string;
  target: string;
}

// 在文件开头添加触摸相关的接口
interface TouchState {
  canvasBlank: boolean;
  fingers: number;
  isDragging: boolean;
  isZooming: boolean;
  lastTouchX: number;
  lastTouchY: number;
  initialDistance: number;
  initialScale: number;
}

// 自定义日志函数，将日志发送到 Flutter
function log(type: "error" | "info" | "warn", ...args: any[]) {
  const message = {
    type: type,
    payload: args
      .map((arg) =>
        typeof arg === "object" ? JSON.stringify(arg) : String(arg)
      )
      .join("\n"),
  };
  if (window.chrome?.webview) {
    window.chrome.webview.postMessage(JSON.stringify(message));
  } else {
    if (type === "error") {
      console.error(JSON.stringify(args, null, 2));
    } else if (type === "info") {
      console.info(JSON.stringify(args, null, 2));
    } else if (type === "warn") {
      console.warn(JSON.stringify(args, null, 2));
    }
  }
}

// 添加防抖函数
function debounce(func: Function): (...args: any[]) => void {
  let timeout: number | null = null;
  return function (...args: any[]) {
    if (timeout !== null) {
      window.cancelAnimationFrame(timeout);
    }
    timeout = window.requestAnimationFrame(() => {
      // @ts-ignore
      func.apply(this, args);
      timeout = null;
    });
  };
}

window.initGraph = async function (containerId: string): Promise<void> {
  log("info", "initGraph", containerId);
  try {
    const container = document.getElementById(containerId);
    if (!container) {
      throw new Error(`Container ${containerId} not found`);
    }
    log(
      "info",
      "Container size:",
      container.clientWidth,
      container.clientHeight
    );

    graph = new Graph({
      container,
      width: container.clientWidth,
      height: container.clientHeight,
      grid: {
        visible: true,
        type: "dot",
        size: 10,
        args: {
          color: "#E2E2E2",
        },
      },
      connecting: {
        snap: true,
        allowBlank: false,
        highlight: true,
        connector: "smooth",
        connectionPoint: "boundary",
        router: {
          name: "er",
          args: {
            padding: 20,
          },
        },
      },
      interacting: {
        nodeMovable: true,
        edgeMovable: true,
        magnetConnectable: true,
      },
      mousewheel: {
        enabled: true,
        modifiers: [],
      },
      panning: {
        enabled: true,
      },
    });

    window.addEventListener("resize", () => {
      graph?.resize(container.clientWidth, container.clientHeight);
    });

    graph.on(
      "node:moved",
      ({ node, x, y }: { node: Node; x: number; y: number }) => {
        window.onNodeMoved?.({
          id: node.id,
          position: { x, y },
        });
      }
    );
    log("info", "Graph initialized successfully");

    // 触摸状态
    const touchState: TouchState = {
      canvasBlank: false,
      fingers: 0,
      isDragging: false,
      isZooming: false,
      lastTouchX: 0,
      lastTouchY: 0,
      initialDistance: 0,
      initialScale: 1,
    };

    // 计算两点之间的距离
    const getDistance = (p1: Touch, p2: Touch) => {
      const dx = p1.clientX - p2.clientX;
      const dy = p1.clientY - p2.clientY;
      const distance = Math.sqrt(dx * dx + dy * dy);
      log("info", "Touch distance:", distance);
      return distance;
    };

    // 计算两点的中心点
    const getMidPoint = (p1: Touch, p2: Touch) => {
      const midPoint = {
        x: (p1.clientX + p2.clientX) / 2,
        y: (p1.clientY + p2.clientY) / 2,
      };
      log("info", "Touch midpoint:", midPoint);
      return midPoint;
    };

    if (graph) {
      // 监听空白区域的触摸开始
      graph.on("blank:mousedown", (e) => {
        touchState.canvasBlank = true;
      });
      graph.on("blank:mouseup", () => {
        touchState.canvasBlank = false;
      });

      // 优化触摸移动处理函数
      const handleTouchMove = debounce((e: TouchEvent) => {
        if (!graph) return;
        if (!touchState.canvasBlank) return;

        if (touchState.isDragging && touchState.fingers === 1) {
          log("info", "Touch move event");
          const touch = e.touches[0];
          const deltaX = touch.clientX - touchState.lastTouchX;
          const deltaY = touch.clientY - touchState.lastTouchY;

          graph.translateBy(deltaX, deltaY);

          touchState.lastTouchX = touch.clientX;
          touchState.lastTouchY = touch.clientY;
        } else if (touchState.isZooming && touchState.fingers === 2) {
          log("info", "scale");
          const touch1 = e.touches[0];
          const touch2 = e.touches[1];

          const distance = getDistance(touch1, touch2);
          const scale =
            (distance / touchState.initialDistance) * touchState.initialScale;
          const limitedScale = Math.min(Math.max(scale, 0.5), 3);
          const center = getMidPoint(touch1, touch2);

          log("info", "Zooming:", {
            distance,
            scale,
            limitedScale,
            center,
            initialScale: touchState.initialScale,
            initialDistance: touchState.initialDistance,
          });

          graph.zoom(limitedScale, {
            absolute: true,
            center: {
              x: center.x,
              y: center.y,
            },
          });
        }

        e.preventDefault();
      });

      // 监听触摸结束
      const handleTouchEnd = () => {
        log("info", "Touch end event:", {
          previousState: {
            isDragging: touchState.isDragging,
            isZooming: touchState.isZooming,
          },
        });
        touchState.isDragging = false;
        touchState.isZooming = false;
        touchState.fingers = 0;
      };

      // 优化事件监听器选项
      if (container) {
        container.addEventListener("touchstart", (e) => {
          const touch = e;
          touchState.fingers = touch.touches?.length;
          if (touch.touches?.length === 1) {
            touchState.isDragging = true;
            touchState.lastTouchX = touch.touches[0].clientX;
            touchState.lastTouchY = touch.touches[0].clientY;
            log("info", "Single touch start:", {
              x: touchState.lastTouchX,
              y: touchState.lastTouchY,
            });
          } else if (touch.touches?.length === 2) {
            touchState.isZooming = true;
            touchState.initialDistance = getDistance(
              touch.touches[0],
              touch.touches[1]
            );
            touchState.initialScale = graph!.scale().sx;
            log("info", "Pinch zoom start:", {
              initialDistance: touchState.initialDistance,
              initialScale: touchState.initialScale,
            });
          }
        });
        container.addEventListener("touchmove", handleTouchMove, {
          passive: false,
        });
        container.addEventListener("touchend", handleTouchEnd, {
          passive: true,
        });
        container.addEventListener("touchcancel", handleTouchEnd, {
          passive: true,
        });
      }
    }
  } catch (error) {
    log("error", "Failed to initialize graph:", error);
  }

  // 监听图形事件
};

// 添加节点
window.addNode = function (nodeData: NodeData) {
  log("info", "Adding node:", nodeData.id);
  if (!graph) {
    log("error", "Error: Graph not initialized");
    return null;
  }
  const node = graph.addNode({
    id: nodeData.id,
    x: nodeData.x,
    y: nodeData.y,
    width: nodeData.width || 100,
    height: nodeData.height || 40,
    label: nodeData.label,
    shape: "rect",
    attrs: {
      body: {
        fill: "#fff",
        stroke: "#8f8f8f",
        strokeWidth: 1,
        rx: 6,
        ry: 6,
      },
      label: {
        text: nodeData.label,
        fill: "#333",
        fontSize: 14,
        fontFamily: "Arial, helvetica, sans-serif",
      },
    },
    ports: {
      groups: {
        in: {
          position: "left",
          attrs: {
            circle: {
              r: 4,
              magnet: true,
              stroke: "#8f8f8f",
              fill: "#fff",
            },
          },
        },
        out: {
          position: "right",
          attrs: {
            circle: {
              r: 4,
              magnet: true,
              stroke: "#8f8f8f",
              fill: "#fff",
            },
          },
        },
      },
      items: [{ group: "in" }, { group: "out" }],
    },
  });

  log("info", "Node added successfully:", nodeData.id);
  return {
    id: node.id,
    position: node.getPosition(),
  };
};

// 添加边
window.addEdge = function (edgeData: EdgeData) {
  if (!graph) return null;

  const edge = graph.addEdge({
    source: edgeData.source,
    target: edgeData.target,
    attrs: {
      line: {
        stroke: "#8f8f8f",
        strokeWidth: 1,
        targetMarker: {
          name: "classic",
          size: 8,
        },
      },
    },
    router: {
      name: "er",
      args: {
        padding: 20,
      },
    },
    connector: {
      name: "rounded",
      args: {
        radius: 8,
      },
    },
  });

  return {
    id: edge.id,
    source: edge.getSource(),
    target: edge.getTarget(),
  };
};

// 处理来自 Flutter 的消息
window.handleFlutterMessage = function (message: string): void {
  try {
    const data = JSON.parse(message);
    log("info", "Received message:", data.type);

    switch (data.type) {
      case "addNode":
        if (!graph) {
          throw new Error("Graph not initialized when adding node");
        }
        window.addNode(data.payload);
        break;
      case "addEdge":
        if (!graph) {
          throw new Error("Graph not initialized when adding edge");
        }
        window.addEdge(data.payload);
        break;
      default:
        throw new Error(`Unknown message type: ${data.type}`);
    }
  } catch (error: any) {
    log("error", "Error in handleFlutterMessage:", error.message);
    // 确保错误被抛出到 WebView
    throw error;
  }
};

// 导出函数类型
export type { NodeData, EdgeData };
