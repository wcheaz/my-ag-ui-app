"use client";

import { ProcurementCodes } from "@/components/procurement-codes";
import { AgentState } from "@/lib/types";
import {
  useCoAgent,
  useCopilotReadable,
  useFrontendTool,
} from "@copilotkit/react-core";
import { CopilotKitCSSProperties, CopilotSidebar, InputProps } from "@copilotkit/react-ui";
import { CopilotTextarea } from "@copilotkit/react-textarea";
import { useState, useRef, ChangeEvent } from "react";
import Papa from "papaparse";
import { read, utils } from "xlsx";

export default function CopilotKitPage() {
  const [themeColor, setThemeColor] = useState("#dc2626");

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
          initial: "Hi! I can help you generate procurement codes given the description of an item.",
        }}
        suggestions={[
          {
            title: "Explain Code Generation",
            message: "How can I generate a procurement code?",
          },
        ]}
        Input={CustomInput}
      >
        <YourMainContent themeColor={themeColor} />
      </CopilotSidebar>
    </main>
  );
}

function CustomInput(props: InputProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [text, setText] = useState("");
  const [attachedFiles, setAttachedFiles] = useState<{ name: string, content: string }[]>([]);

  // Safety limits: ~400k chars is approx 100k tokens. Limit file size to avoid reading massive files.
  const MAX_TOTAL_CHARS = 400000;
  const MAX_FILE_SIZE_BYTES = 2 * 1024 * 1024; // 2MB

  const handleFileUpload = (event: ChangeEvent<HTMLInputElement>) => {
    const files = event.target.files;
    if (!files || files.length === 0) return;

    const newFiles: { name: string, content: string }[] = [];
    let processedCount = 0;

    Array.from(files).forEach(file => {
      // 1. Check File Size BEFORE reading
      if (file.size > MAX_FILE_SIZE_BYTES) {
        alert(`File "${file.name}" is too large (max 2MB). Skipping.`);
        processedCount++;
        if (processedCount === files.length) finalizeUpload(newFiles);
        return;
      }

      const processFileContent = (name: string, content: string) => {
        // 2. Check cumulative Length
        const currentTotal = attachedFiles.reduce((sum, f) => sum + f.content.length, 0);
        const newTotal = newFiles.reduce((sum, f) => sum + f.content.length, 0);

        if (currentTotal + newTotal + content.length > MAX_TOTAL_CHARS) {
          alert(`Upload limit reached! Adding "${name}" would exceed the maximum context size. Please upload files in smaller batches.`);
        } else {
          newFiles.push({ name: name, content });
        }

        processedCount++;
        if (processedCount === files.length) {
          finalizeUpload(newFiles);
        }
      };

      // Handle CSV files
      if (file.type === "text/csv" || file.name.endsWith(".csv")) {
        Papa.parse(file, {
          complete: (results) => {
            // Unparse back to string to ensure clean formatting
            const csvString = Papa.unparse(results.data);
            processFileContent(file.name, csvString);
          },
          error: (error) => {
            console.error("CSV Parse Error:", error);
            alert(`Failed to parse CSV file "${file.name}".`);
            processedCount++;
            if (processedCount === files.length) finalizeUpload(newFiles);
          }
        });
        return;
      }

      // Handle Excel files
      if (file.type === "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" ||
        file.type === "application/vnd.ms-excel" ||
        file.name.endsWith(".xlsx") ||
        file.name.endsWith(".xls") ||
        file.name.endsWith(".xml")) {
        const reader = new FileReader();
        reader.onload = (e) => {
          try {
            const data = e.target?.result;
            const workbook = read(data, { type: 'array' });
            // Convert first sheet to CSV
            const firstSheetName = workbook.SheetNames[0];
            const worksheet = workbook.Sheets[firstSheetName];
            const csvContent = utils.sheet_to_csv(worksheet);
            processFileContent(file.name, csvContent);
          } catch (error) {
            console.error("Excel Parse Error:", error);
            alert(`Failed to parse Excel file "${file.name}".`);
            processedCount++;
            if (processedCount === files.length) finalizeUpload(newFiles);
          }
        };
        reader.readAsArrayBuffer(file);
        return;
      }

      // Handle Text files
      if (file.type === "text/plain" || file.name.endsWith(".txt")) {
        const reader = new FileReader();
        reader.onload = (e) => {
          const content = e.target?.result as string;
          processFileContent(file.name, content);
        };
        reader.readAsText(file);
        return;
      }

      // Fallback for unsupported types
      processedCount++;
      if (processedCount === files.length) finalizeUpload(newFiles);
    });
  };

  const finalizeUpload = (newFiles: { name: string, content: string }[]) => {
    setAttachedFiles(prev => [...prev, ...newFiles]);
    if (fileInputRef.current) {
      fileInputRef.current.value = "";
    }
  };

  const removeFile = (index: number) => {
    setAttachedFiles(prev => prev.filter((_, i) => i !== index));
  };

  const handleSend = () => {
    // Allow sending if there is text OR attached files
    if (!text.trim() && attachedFiles.length === 0) return;

    let messageContent = text;

    if (attachedFiles.length > 0) {
      const fileContexts = attachedFiles.map(f => `[Context from uploaded file "${f.name}"]:\n${f.content}`).join("\n\n");
      if (messageContent) {
        messageContent = `${messageContent}\n\n${fileContexts}`;
      } else {
        messageContent = fileContexts;
      }
    }

    props.onSend(messageContent);
    setText("");
    setAttachedFiles([]);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  return (
    <div className="relative w-full p-4 bg-[#111111] border-t border-[#2a2a2a]">
      {/* File Previews */}
      {attachedFiles.length > 0 && (
        <div className="flex flex-wrap gap-2 mb-2">
          {attachedFiles.map((file, index) => (
            <div key={index} className="flex items-center gap-2 p-2 bg-[#1a1a1a] border border-[#2a2a2a] rounded-md w-fit animate-in fade-in slide-in-from-bottom-1 duration-200">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-4 h-4 text-[#dc2626]">
                <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z" />
              </svg>
              <span className="text-sm text-[#e0e0e0] font-medium truncate max-w-[150px]">{file.name}</span>
              <button
                onClick={() => removeFile(index)}
                className="ml-1 text-[#666666] hover:text-[#e0e0e0] focus:outline-none"
              >
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4">
                  <path d="M6.28 5.22a.75.75 0 0 0-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 1 0 1.06 1.06L10 11.06l3.72 3.72a.75.75 0 1 0 1.06-1.06L11.06 10l3.72-3.72a.75.75 0 0 0-1.06-1.06L10 8.94 6.28 5.22Z" />
                </svg>
              </button>
            </div>
          ))}
        </div>
      )}

      {props.inProgress && (
        <div className="flex items-center gap-2 mb-2 px-1 text-sm text-[#e0e0e0] animate-pulse">
          <svg className="w-3.5 h-3.5 animate-spin" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
          </svg>
          <span>Processing your request<span className="text-[#dc2626]">...</span></span>
        </div>
      )}

      <div className="relative flex items-center w-full border border-[#2a2a2a] rounded-lg focus-within:ring-2 focus-within:ring-[#dc2626] overflow-hidden bg-[#0a0a0a]">

        {/* Upload Button */}
        <button
          onClick={() => fileInputRef.current?.click()}
          className="p-3 text-[#e0e0e0] hover:text-[#dc2626] transition-colors border-r border-[#2a2a2a]"
          title="Upload Context"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" className="w-5 h-5">
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
        </button>

        {/* Text Area */}
        <CopilotTextarea
          value={text}
          onChange={(e) => setText(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Type a message..."
          disableBranding
          className="flex-1 w-full max-h-40 overflow-y-auto overflow-x-hidden bg-transparent border-none focus:ring-0 p-3 resize-none outline-none text-base text-[#e0e0e0] placeholder-[#666666]"
          autosuggestionsConfig={{
            textareaPurpose: "Provide details for procurement code generation.",
            chatApiConfigs: {}
          }}
        />

        {/* Send / Spinner Button */}
        {props.inProgress ? (
          <div className="p-3 flex items-center justify-center">
            <svg className="w-5 h-5 animate-spin text-[#dc2626]" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
            </svg>
          </div>
        ) : (
          <button
            onClick={handleSend}
            disabled={!text.trim() && attachedFiles.length === 0}
            className={`p-3 transition-colors ${(!text.trim() && attachedFiles.length === 0) ? "text-[#2a2a2a]" : "text-[#dc2626] hover:bg-[#1a1a1a]"}`}
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5">
              <path d="M3.478 2.404a.75.75 0 0 0-.926.941l2.432 7.905H13.5a.75.75 0 0 1 0 1.5H4.984l-2.432 7.905a.75.75 0 0 0 .926.94 60.519 60.519 0 0 0 18.445-8.986.75.75 0 0 0 0-1.218A60.517 60.517 60.517 60.517 60.517 0 0 0 3.478 2.404Z" />
            </svg>
          </button>
        )}
      </div>

      <input
        type="file"
        ref={fileInputRef}
        className="hidden"
        style={{ display: "none" }}
        accept=".txt,.csv,.xlsx,.xls,.xml"
        multiple
        onChange={handleFileUpload}
      />
    </div>
  );
}

function YourMainContent({
  themeColor,
}: {
  themeColor: string;
}) {
  // themeColor is reserved for future theming functionality
  void themeColor;
  // 🪁 Shared State: https://docs.copilotkit.ai/pydantic-ai/shared-state
  const { state, setState } = useCoAgent<AgentState>({
    name: "my_agent",
    initialState: {
      procurement_codes: [],
    },
  });

  useCopilotReadable({
    description: "The list of generated procurement codes",
    value: JSON.stringify(state.procurement_codes ?? []),
  });

  return (
    <div
      style={{}}
      className="h-screen flex items-center pt-[10vh] flex-col transition-colors duration-300"
    >
      <ProcurementCodes state={state} setState={setState} />
    </div>
  );
}
