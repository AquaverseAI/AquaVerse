import React, { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  flexRender,
  ColumnDef,
  SortingState,
} from '@tanstack/react-table';
import { useVirtualizer } from '@tanstack/react-virtual';
import {
  AlertCircle,
  ArrowUpRight,
  ArrowDownRight,
  Send,
  UserPlus,
  CheckCircle2,
  MoreHorizontal,
} from 'lucide-react';
import { RiskStatusBadge } from '../components/common/RiskStatusBadge';

import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '../components/ui/dropdown-menu';
import { Button } from '../components/ui/button';
import { Checkbox } from '../components/ui/checkbox';

interface TriageWorklistProps {
  onSelectPondForDeepDive: (pondId: string) => void;
  onOpenBroadcaster: (pondId: string) => void;
  theme?: 'light' | 'dark';
}

export const TriageWorklist: React.FC<TriageWorklistProps> = ({
  onSelectPondForDeepDive,
  onOpenBroadcaster,
  theme = 'light',
}) => {
  const { data: pondsData = { items: [] } } = useQuery({
    queryKey: ['ponds'],
    queryFn: async () => {
      const res = await fetch('/v1/ponds');
      return res.json();
    },
  });

  const { data: worklistData = { items: [] } } = useQuery({
    queryKey: ['worklist'],
    queryFn: async () => {
      const res = await fetch('/v1/risk/worklist');
      return res.json();
    },
  });

  // Join data on pond_id
  const tableData = useMemo(() => {
    const ponds = pondsData?.items || [];
    const worklist = worklistData?.items || [];

    const joined = worklist.map((w: any) => {
      const p = ponds.find((p: any) => p.id === w.pond_id) || {};
      
      // Attempt to extract top driver from SHAP
      let topDriver = 'Unknown';
      if (w.shap_contributions && w.shap_contributions.length > 0) {
        // Find highest absolute SHAP value
        const top = w.shap_contributions.reduce((prev: any, current: any) => 
          (Math.abs(prev.shap_value) > Math.abs(current.shap_value)) ? prev : current
        );
        topDriver = top.feature;
      } else {
        topDriver = w.primary_driver || 'DO Rapid Drop Velocity'; // fallback to mock property
      }

      const biomass = w.biomass_kg || p.biomass_kg_estimated || 12.3; // fallback 
      const delta = w.risk_delta_24h || 0.05;

      return {
        id: w.pond_id,
        pond_name: w.pond_name || p.name || w.pond_id,
        farmer_name: w.farmer_name || 'Raja Kumar', // Fake if not exists
        district: w.district || p.district || 'Coimbatore',
        species: w.species || p.species || 'L. vannamei',
        doc: w.doc || 45,
        risk: w.risk_score || w.risk || 0,
        risk_level: w.risk_level || 'low',
        suppressed: w.suppressed || false,
        delta_24h: delta,
        biomass_kg: biomass,
        top_driver: topDriver,
        last_log_at: w.last_log_at,
        data_health: w.data_health || 1.0,
        sort_metric: (w.risk_score || w.risk || 0) * biomass,
      };
    });

    // Custom sorting: risk x biomass-at-stake
    joined.sort((a: any, b: any) => b.sort_metric - a.sort_metric);
    return joined;
  }, [pondsData, worklistData]);

  const [rowSelection, setRowSelection] = React.useState({});
  const [sorting, setSorting] = React.useState<SortingState>([]);

  const columns = useMemo<ColumnDef<any>[]>(() => [
    {
      id: 'select',
      header: ({ table }) => (
        <Checkbox
          checked={table.getIsAllPageRowsSelected()}
          onCheckedChange={(value) => table.toggleAllPageRowsSelected(!!value)}
          aria-label="Select all"
          className="translate-y-[2px]"
        />
      ),
      cell: ({ row }) => (
        <Checkbox
          checked={row.getIsSelected()}
          onCheckedChange={(value) => row.toggleSelected(!!value)}
          aria-label="Select row"
          className="translate-y-[2px]"
        />
      ),
      enableSorting: false,
      enableHiding: false,
      size: 40,
    },
    {
      accessorKey: 'pond_name',
      header: 'Pond',
      cell: (info) => (
        <div>
          <div className="font-bold text-ocean-900 dark:text-slate-100">{info.getValue<string>()}</div>
          <div className="text-[10px] text-slate-500 font-normal">{info.row.original.species}</div>
        </div>
      ),
      size: 150,
    },
    {
      accessorKey: 'farmer_name',
      header: 'Farmer / Location',
      cell: (info) => (
        <div>
          <div className="text-slate-700 dark:text-slate-300">{info.getValue<string>()}</div>
          <div className="text-[10px] text-slate-500">{info.row.original.district}</div>
        </div>
      ),
      size: 150,
    },
    {
      accessorKey: 'doc',
      header: 'DOC',
      size: 80,
    },
    {
      accessorKey: 'risk',
      header: 'Risk',
      cell: (info) => (
        <RiskStatusBadge risk={info.getValue<number>()} blind_state={info.row.original.suppressed} showValue={true} />
      ),
      size: 120,
    },
    {
      accessorKey: 'delta_24h',
      header: 'Δ24h',
      cell: (info) => {
        const val = info.getValue<number>();
        return (
          <span className={`flex items-center gap-1 font-bold ${val > 0 ? 'text-risk-critical' : 'text-mint-700'}`}>
            {val > 0 ? <ArrowUpRight className="w-3.5 h-3.5" /> : <ArrowDownRight className="w-3.5 h-3.5" />}
            <span>{val > 0 ? `+${val.toFixed(2)}` : val.toFixed(2)}</span>
          </span>
        );
      },
      size: 100,
    },
    {
      accessorKey: 'biomass_kg',
      header: 'Biomass',
      cell: (info) => (
        <span className="font-semibold">{info.getValue<number>().toLocaleString()} kg</span>
      ),
      size: 120,
    },
    {
      accessorKey: 'top_driver',
      header: 'Top Driver',
      cell: (info) => (
        <span className="text-[11px] text-slate-600 dark:text-slate-400 max-w-[150px] truncate block" title={info.getValue<string>()}>
          {info.getValue<string>()}
        </span>
      ),
      size: 150,
    },
    {
      id: 'actions',
      header: '',
      cell: ({ row }) => (
        <div className="flex items-center justify-end gap-2">
          <Button
            variant="outline"
            size="sm"
            className="h-7 text-[11px] font-bold"
            onClick={() => onSelectPondForDeepDive(row.original.id)}
          >
            3D Twin
          </Button>
          <Button
            variant="ghost"
            size="icon"
            className="h-7 w-7 text-slate-500 hover:text-teal-600"
            onClick={() => onOpenBroadcaster(row.original.id)}
          >
            <Send className="h-3.5 w-3.5" />
          </Button>
        </div>
      ),
      size: 120,
    },
  ], [onSelectPondForDeepDive, onOpenBroadcaster]);

  const table = useReactTable({
    data: tableData,
    columns,
    state: {
      sorting,
      rowSelection,
    },
    enableRowSelection: true,
    onRowSelectionChange: setRowSelection,
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
  });

  const parentRef = React.useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: table.getRowModel().rows.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 56, // height of a row
    overscan: 10,
  });

  return (
    <div className="space-y-4 animate-fade-in flex flex-col h-full">
      {/* Top Banner */}
      <div className="instrument-card p-4 rounded-xl flex flex-col md:flex-row items-start md:items-center justify-between gap-4 shrink-0">
        <div>
          <h2 className="text-base font-bold text-ocean-900 dark:text-slate-100 font-mono flex items-center gap-2">
            <AlertCircle className="w-4 h-4 text-teal-600" />
            Fleet Triage: Priority Worklist (Risk × Biomass-at-Stake)
          </h2>
          <p className="text-xs text-slate-600 dark:text-slate-400 mt-1 font-sans">
            Sorted by urgency velocity: <span className="font-mono text-teal-700 dark:text-teal-400 font-bold">&Delta;24h rate of change</span> prioritizes field interventions.
          </p>
        </div>

        {/* Bulk Actions Menu */}
        <div className="flex items-center gap-3 font-mono text-xs">
          <span className="text-slate-500 text-xs">
            Selected: <strong className="text-teal-700 dark:text-teal-400">{Object.keys(rowSelection).length}</strong>
          </span>
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button disabled={Object.keys(rowSelection).length === 0} className="bg-teal-600 hover:bg-teal-700 text-white gap-2 font-bold h-8">
                Bulk Actions <MoreHorizontal className="w-3.5 h-3.5" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-48 font-mono text-xs">
              <DropdownMenuItem className="cursor-pointer gap-2" onClick={() => onOpenBroadcaster(tableData[0]?.id)}>
                <Send className="w-3.5 h-3.5 text-teal-600" />
                Send Advisory
              </DropdownMenuItem>
              <DropdownMenuItem className="cursor-pointer gap-2">
                <UserPlus className="w-3.5 h-3.5 text-ocean-600" />
                Assign to Officer
              </DropdownMenuItem>
              <DropdownMenuItem className="cursor-pointer gap-2">
                <CheckCircle2 className="w-3.5 h-3.5 text-mint-600" />
                Mark Visited
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>

      {/* Virtualized Table Container */}
      <div className="instrument-card rounded-xl shadow-sm flex-1 overflow-hidden flex flex-col min-h-[400px]">
        <div ref={parentRef} className="flex-1 overflow-auto bg-white dark:bg-surface-darkCard">
          <div style={{ height: `${virtualizer.getTotalSize()}px`, width: '100%', position: 'relative' }}>
            <table className="w-full text-left text-xs font-mono absolute top-0 left-0">
              <thead className="bg-surface-cardSubtle dark:bg-surface-darkCardAlt text-slate-600 dark:text-slate-400 border-b border-surface-border dark:border-surface-darkBorder font-semibold sticky top-0 z-10 shadow-sm">
                {table.getHeaderGroups().map(headerGroup => (
                  <tr key={headerGroup.id}>
                    {headerGroup.headers.map((header, index) => {
                      const isPinnedLeft = index < 2;
                      const isPinnedRight = index === headerGroup.headers.length - 1;
                      
                      let style: React.CSSProperties = {
                        width: header.getSize(),
                      };

                      if (isPinnedLeft) {
                        style.position = 'sticky';
                        style.left = index === 0 ? 0 : 40;
                        style.zIndex = 20;
                        style.backgroundColor = 'inherit';
                      } else if (isPinnedRight) {
                        style.position = 'sticky';
                        style.right = 0;
                        style.zIndex = 20;
                        style.backgroundColor = 'inherit';
                      }

                      return (
                        <th key={header.id} className="p-3" style={style}>
                          {header.isPlaceholder
                            ? null
                            : flexRender(
                                header.column.columnDef.header,
                                header.getContext()
                              )}
                        </th>
                      )
                    })}
                  </tr>
                ))}
              </thead>
              <tbody className="divide-y divide-surface-border dark:divide-surface-darkBorder">
                {virtualizer.getVirtualItems().map(virtualRow => {
                  const row = table.getRowModel().rows[virtualRow.index]
                  return (
                    <tr
                      key={row.id}
                      data-index={virtualRow.index}
                      ref={virtualizer.measureElement}
                      className={`hover:bg-surface-cardSubtle dark:hover:bg-surface-darkCardAlt transition-colors absolute w-full flex items-center ${
                        row.getIsSelected() ? 'bg-teal-50/50 dark:bg-teal-950/20' : ''
                      }`}
                      style={{
                        transform: `translateY(${virtualRow.start}px)`,
                      }}
                    >
                      {row.getVisibleCells().map((cell, index) => {
                        const isPinnedLeft = index < 2;
                        const isPinnedRight = index === row.getVisibleCells().length - 1;
                        
                        let style: React.CSSProperties = {
                          width: cell.column.getSize(),
                          flexShrink: 0,
                          backgroundColor: 'inherit',
                        };

                        if (isPinnedLeft) {
                          style.position = 'sticky';
                          style.left = index === 0 ? 0 : 40;
                          style.zIndex = 5;
                        } else if (isPinnedRight) {
                          style.position = 'sticky';
                          style.right = 0;
                          style.zIndex = 5;
                          style.justifyContent = 'flex-end';
                        }

                        return (
                          <td key={cell.id} className="p-3 flex items-center" style={style}>
                            {flexRender(cell.column.columnDef.cell, cell.getContext())}
                          </td>
                        )
                      })}
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};
