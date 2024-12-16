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

// 自定义日志函数，将日志发送到 Flutter
function log(type: "error" | "info" | "warn", ...args: any[]) {
  const message = {
    type: type,
    payload: args
      .map((arg) =>
        typeof arg === "object" ? JSON.stringify(arg) : String(arg)
      )
      .join(" "),
  };
  if (window.chrome?.webview) {
    window.chrome.webview.postMessage(JSON.stringify(message));
  } else {
    if (type === "error") {
      console.error(...args);
    } else if (type === "info") {
      console.log(...args);
    } else if (type === "warn") {
      console.warn(...args);
    }
  }
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
      translating: { restrict: false },
      selecting: {
        enabled: true,
        multiple: true,
        rubberband: true,
        movable: true,
        showNodeSelectionBox: true,
      },
      grid: {
        visible: true,
        type: "dot",
        size: 10,
        args: {
          color: "#E2E2E2",
        },
      },
      resizing: {
        enabled: true,
        autoScroll: true,
      },
      background: {
        color: "#ffffff",
      },
      connecting: {
        snap: true,
        validateConnection: () => false,
        highlight: true,
        connector: "smooth",
        connectionPoint: "boundary",
        router: {
          name: "manhattan",
          args: {
            padding: 1,
          },
        },
      },
      interacting: {
        nodeMovable: true,
        edgeMovable: true,
        edgeLabelMovable: true,
        vertexMovable: true,
        vertexAddable: true,
        vertexDeletable: true,
        magnetConnectable: true,
      },
      mousewheel: {
        enabled: true,
        modifiers: [],
      },
      scroller: {
        enabled: true,
        pannable: true,
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
        magnet: true,
      },
      label: {
        fill: "#333",
        fontSize: 14,
        fontFamily: "Arial, helvetica, sans-serif",
        textWrap: {
          width: -10,
          height: -10,
          ellipsis: true,
        },
      },
    },
  });

  log("info", "Node added successfully:", nodeData.id);
  return {
    id: node.id,
    position: node.position(),
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
      name: "manhattan",
      args: {
        padding: 1,
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
