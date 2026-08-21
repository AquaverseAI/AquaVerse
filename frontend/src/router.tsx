import { createRouter, createRoute, createRootRoute } from '@tanstack/react-router';
import App from './App';
import { DistrictMap } from './pages/DistrictMap';
import { TriageWorklist } from './pages/TriageWorklist';
import { PondDeepDive } from './pages/PondDeepDive';
import { ModelOperations } from './pages/ModelOperations';
import { AdvisoryBroadcaster } from './pages/AdvisoryBroadcaster';
import { DataQuality } from './pages/DataQuality';
import { AnalyticsReports } from './pages/AnalyticsReports';

// We wrap the entire application in the root route
const rootRoute = createRootRoute({
  component: App,
});

const mapRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  component: () => {
    const navigate = mapRoute.useNavigate();
    return <DistrictMap selectedDistrict="Coimbatore" onSelectPondForDeepDive={(id) => navigate({ to: '/ponds/$pondId', params: { pondId: id } })} theme="light" />;
  },
});

const worklistRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/worklist',
  component: () => {
    const navigate = worklistRoute.useNavigate();
    return <TriageWorklist onSelectPondForDeepDive={(id) => navigate({ to: '/ponds/$pondId', params: { pondId: id } })} onOpenBroadcaster={() => navigate({ to: '/broadcaster' })} theme="light" />;
  },
});

const deepdiveRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/ponds/$pondId',
  component: () => {
    // @ts-ignore - Temporary generic bypass
    const { pondId } = deepdiveRoute.useParams({ strict: false });
    return <PondDeepDive pondId={pondId as string} theme="light" />;
  },
});

const modelopsRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/modelops',
  component: () => <ModelOperations theme="light" />,
});

const broadcasterRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/broadcaster',
  component: () => <AdvisoryBroadcaster initialPondId="CBE-003" theme="light" />,
});

const dataqualityRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/dataquality',
  component: () => <DataQuality theme="light" />,
});

const analyticsRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/analytics',
  component: () => <AnalyticsReports theme="light" />,
});

const routeTree = rootRoute.addChildren([
  mapRoute,
  worklistRoute,
  deepdiveRoute,
  modelopsRoute,
  broadcasterRoute,
  dataqualityRoute,
  analyticsRoute,
]);

export const router = createRouter({ routeTree });

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router;
  }
}
