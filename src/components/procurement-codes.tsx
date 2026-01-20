import { AgentState } from "@/lib/types";

export interface ProcurementCodesProps {
    state: AgentState;
    setState: (state: AgentState) => void;
}

export function ProcurementCodes({ state, setState }: ProcurementCodesProps) {
    return (
        <div className="bg-white/20 backdrop-blur-md p-8 rounded-2xl shadow-xl max-w-2xl w-full">
            <h1 className="text-4xl font-bold text-white mb-2 text-center">Procurement Codes</h1>
            <p className="text-gray-200 text-center italic mb-6">Generated procurement codes and descriptions.</p>
            <hr className="border-white/20 my-6" />
            <div className="flex flex-col gap-3">
                {state.procurement_codes?.map((item, index) => (
                    <div
                        key={index}
                        className="bg-white/15 p-4 rounded-xl text-white relative group hover:bg-white/20 transition-all"
                    >
                        <div className="pr-8">
                            <span className="font-mono font-bold bg-black/20 px-2 py-1 rounded text-yellow-300 mr-2">{item.code}</span>
                            <span>{item.description}</span>
                        </div>
                        <button
                            onClick={() => setState({
                                ...state,
                                procurement_codes: state.procurement_codes?.filter((_, i) => i !== index),
                            })}
                            className="absolute right-3 top-3 opacity-0 group-hover:opacity-100 transition-opacity 
                bg-red-500 hover:bg-red-600 text-white rounded-full h-6 w-6 flex items-center justify-center"
                        >
                            ✕
                        </button>
                    </div>
                ))}
            </div>
            {(state.procurement_codes?.length === 0 || !state.procurement_codes) && <p className="text-center text-white/80 italic my-8">
                No procurement codes generated yet...
            </p>}
        </div>
    );
}
