import { AgentState } from "@/lib/types";
import { utils, writeFile } from "xlsx";
import "./procurement-codes.css";

export interface ProcurementCodesProps {
    state: AgentState;
    setState: (state: AgentState) => void;
}

export function ProcurementCodes({ state, setState }: ProcurementCodesProps) {
    const handleDownloadText = () => {
        if (!state.procurement_codes?.length) return;

        const content = state.procurement_codes
            .map(item => `${item.code} - ${item.description}`)
            .join('\n');

        const blob = new Blob([content], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'procurement_codes.txt';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    };

    const handleDownloadCSV = () => {
        if (!state.procurement_codes?.length) return;

        const ws = utils.json_to_sheet(state.procurement_codes.map(item => ({
            Code: item.code,
            Description: item.description
        })));
        const csv = utils.sheet_to_csv(ws);
        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'procurement_codes.csv';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    };

    const handleDownloadExcel = () => {
        if (!state.procurement_codes?.length) return;

        const ws = utils.json_to_sheet(state.procurement_codes.map(item => ({
            Code: item.code,
            Description: item.description
        })));
        const wb = utils.book_new();
        utils.book_append_sheet(wb, ws, "Procurement Codes");
        writeFile(wb, "procurement_codes.xlsx");
    };

    return (
        <div className="pc-card">
            <div className="pc-title-wrapper">
                <h1 className="pc-title">Procurement Codes</h1>
            </div>
            <p className="pc-subtitle">Previously generated procurement codes and descriptions.</p>

            {state.procurement_codes && state.procurement_codes.length > 0 && (
                <div className="pc-download-bar">
                    <button
                        onClick={handleDownloadText}
                        className="pc-download-btn"
                        title="Download as Text"
                    >
                        <span>TXT</span>
                        <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                        </svg>
                    </button>
                    <button
                        onClick={handleDownloadCSV}
                        className="pc-download-btn"
                        title="Download as CSV"
                    >
                        <span>CSV</span>
                        <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M3 14h18m-9-4v8m-7-2.5l7.5-7.5 7.5 7.5" />
                        </svg>
                    </button>
                    <button
                        onClick={handleDownloadExcel}
                        className="pc-download-btn"
                        title="Download as Excel"
                    >
                        <span>XLSX</span>
                        <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                        </svg>
                    </button>
                </div>
            )}

            <hr className="pc-divider" />
            <div className="pc-list">
                {state.procurement_codes?.map((item, index) => (
                    <div key={item.id ?? index} className="pc-item">
                        <div className="pc-item-inner">
                            <span className="pc-id-badge">#{item.id}</span>
                            <span className="pc-code-badge">{item.code}</span>
                            <span>{item.description}</span>
                        </div>
                        <button
                            onClick={() => setState({
                                ...state,
                                procurement_codes: state.procurement_codes?.filter((c) => c.id !== item.id),
                            })}
                            className="pc-delete-btn"
                        >
                            ✕
                        </button>
                    </div>
                ))}
            </div>

            {(state.procurement_codes?.length === 0 || !state.procurement_codes) && <p className="pc-empty-state">
                No previously generated procurement codes detected.
            </p>}
        </div>
    );
}
