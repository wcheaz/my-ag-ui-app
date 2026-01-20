// State of the agent, make sure this aligns with your agent's state.
// State of the agent, make sure this aligns with your agent's state.
export type ProcurementCode = {
  code: string;
  description: string;
};

export type AgentState = {
  procurement_codes: ProcurementCode[];
}