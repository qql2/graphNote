import { Graph, Node } from "@antv/x6";

declare global {
  interface Window {
    onNodeMoved?: (data: {
      id: string;
      position: { x: number; y: number };
    }) => void;
    initGraph: (containerId: string) => void;
    addNode: (nodeData: NodeData) => any;
    addEdge: (edgeData: EdgeData) => any;
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

window.initGraph = function (containerId: string): void {
  console.log("initGraph", containerId);
  console.log("container element:", document.getElementById(containerId));
  try {
    graph = new Graph({
      container: document.getElementById(containerId)!,
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
        modifiers: ["ctrl", "meta"],
      },
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
    console.log("Graph initialized successfully:", graph);
  } catch (error) {
    console.error("Failed to initialize graph:", error);
  }

  // 监听图形事件
};

// 添加节点
window.addNode = function (nodeData: NodeData) {
  console.log("addNode", nodeData);
  if (!graph) {
    console.error("Graph not initialized");
    return null;
  }

  const node = graph.addNode({
    id: nodeData.id,
    x: nodeData.x,
    y: nodeData.y,
    width: nodeData.width || 100,
    height: nodeData.height || 40,
    label: nodeData.label,
    attrs: {
      body: {
        fill: "#fff",
        stroke: "#8f8f8f",
        strokeWidth: 1,
        rx: 6,
        ry: 6,
      },
      label: {
        fill: "#333",
        fontSize: 14,
        fontFamily: "Arial, helvetica, sans-serif",
      },
    },
  });

  console.log("Node added:", node);
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

// 导出函数类型
export type { NodeData, EdgeData };
