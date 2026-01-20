"use client";

import { ProcurementCodes } from "@/components/procurement-codes";
import { AgentState } from "@/lib/types";
import {
  useCoAgent,
  useCopilotReadable,
  useFrontendTool,
} from "@copilotkit/react-core";
import { CopilotKitCSSProperties, CopilotSidebar } from "@copilotkit/react-ui";
import { useState } from "react";

export default function CopilotKitPage() {
  const [themeColor, setThemeColor] = useState("#363636ff");

  // 🪁 Frontend Actions: https://docs.copilotkit.ai/pydantic-ai/frontend-actions
  useFrontendTool({
    name: "setThemeColor",
    parameters: [
      {
        name: "themeColor",
        description: "The theme color to set. Make sure to pick nice colors.",
        required: true,
      },
    ],
    handler({ themeColor }) {
      setThemeColor(themeColor);
    },
  });

  return (
    <main
      style={
        { "--copilot-kit-primary-color": themeColor } as CopilotKitCSSProperties
      }
    >
      <CopilotSidebar
        defaultOpen={true}
        disableSystemMessage={true}
        clickOutsideToClose={false}
        labels={{
          title: "Procurement Assistant",
          initial: "👋 Hi! I can help you generate procurement codes.",
        }}
        suggestions={[
          {
            title: "Explain Code Generation",
            message: "How can I generate a procurement code?",
          },
        ]}
      >
        <YourMainContent themeColor={themeColor} />
      </CopilotSidebar>
    </main>
  );
}

function YourMainContent({ themeColor }: { themeColor: string }) {
  // 🪁 Shared State: https://docs.copilotkit.ai/pydantic-ai/shared-state
  const { state, setState } = useCoAgent<AgentState>({
    name: "my_agent",
    initialState: {
      procurement_codes: [],
    },
  });

  useCopilotReadable({
    description: "The list of generated procurement codes",
    value: state.procurement_codes,
  });

  return (
    <div
      style={{}}
      className="h-screen flex justify-center items-center flex-col transition-colors duration-300"
    >
      <ProcurementCodes state={state} setState={setState} />
    </div>
  );
}
