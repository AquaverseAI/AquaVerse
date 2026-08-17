import React from 'react';

export interface RiskStatusBadgeProps {
  risk: number;
  blind_state: boolean;
  showValue?: boolean;
  suffix?: string;
}

const getRiskStatusText = (risk: number, blind_state: boolean): string => {
  if (blind_state) {
    return 'BLIND STATE';
  }
  if (risk >= 0.7) {
    return 'CRITICAL RISK';
  }
  if (risk >= 0.4) {
    return 'ELEVATED RISK';
  }
  return 'OPTIMAL STABILITY';
};

const getRiskBadgeClass = (risk: number, blind_state: boolean, isValueMode: boolean, isDark: boolean): string => {
  if (blind_state) {
    return isValueMode
      ? 'bg-slate-100 text-slate-700 border-slate-300 dark:bg-slate-800 dark:text-slate-300'
      : 'bg-slate-100 text-slate-700 border-slate-300 dark:bg-slate-800 dark:text-slate-300';
  }
  if (risk >= 0.7) {
    return isValueMode
      ? 'bg-risk-criticalBg text-risk-critical border-risk-criticalBorder'
      : 'bg-risk-criticalBg text-risk-critical border-risk-criticalBorder';
  }
  if (risk >= 0.4) {
    return isValueMode
      ? 'bg-risk-warningBg text-risk-warning border-risk-warningBorder'
      : 'bg-risk-warningBg text-risk-warning border-risk-warningBorder';
  }
  return isValueMode
    ? 'bg-risk-healthyBg text-mint-700 dark:text-mint-400 border-risk-healthyBorder'
    : 'bg-risk-healthyBg text-mint-700 dark:text-mint-400 border-risk-healthyBorder';
};

export const RiskStatusBadge: React.FC<RiskStatusBadgeProps> = ({ risk, blind_state, showValue = false, suffix = '' }) => {
  const isDark = document.documentElement.classList.contains('dark');
  const isValueMode = showValue;

  if (isValueMode) {
    // Display risk number with color coding and optional suffix (for TriageWorklist, PondDigitalTwin3D HUD)
    const displaySuffix = suffix ? ` ${suffix}` : '';
    return (
      <span className={`inline-block px-2 py-0.5 rounded-full font-bold text-xs border ${getRiskBadgeClass(risk, blind_state, true, isDark)}${suffix ? ' font-mono' : ''}`}>
        {risk.toFixed(2)}${displaySuffix}
      </span>
    );
  }

  // Display risk status text (for ExplanationCard, DistrictMap classification)
  const riskStatusText = getRiskStatusText(risk, blind_state);
  return (
    <span className={`text-xs font-mono font-bold rounded-full border shadow-xs ${getRiskBadgeClass(risk, blind_state, false, isDark)}`}>
      {riskStatusText}
    </span>
  );
};