export function formatDateTime(value: string) {
  return new Intl.DateTimeFormat('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value));
}

export function formatCompactNumber(value: number) {
  return new Intl.NumberFormat('zh-CN', {
    notation: value > 999 ? 'compact' : 'standard',
    maximumFractionDigits: 1,
  }).format(value);
}

export function formatPercent(value: number) {
  return `${value.toFixed(1)}%`;
}

export function formatTrend(value: number) {
  if (value === 0) {
    return '较上周持平';
  }

  if (value > 0) {
    return `较上周提升 ${value.toFixed(1)}%`;
  }

  return `较上周下降 ${Math.abs(value).toFixed(1)}%`;
}
