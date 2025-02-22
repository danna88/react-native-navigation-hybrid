import { Platform } from 'react-native';
import {
  EventEmitter,
  NavigationModule,
  EVENT_WILL_SET_ROOT,
  EVENT_DID_SET_ROOT,
  EVENT_SWITCH_TAB,
  KEY_SCENE_ID,
  KEY_INDEX,
  KEY_MODULE_NAME,
} from './NavigationModule';
import { bindBarButtonItemClickEvent } from './utils';
import store from './store';
import { NavigationItem } from './Garden';
import { Route, RouteGraph } from './router';

let intercept: NavigationInterceptor;
let willSetRootCallback: () => void;
let didSetRootCallback: () => void;

interface Extras {
  sceneId: string;
  index?: number;
}

interface Params {
  animated?: boolean;
  moduleName?: string;
  layout?: Layout;
  index?: number;
  popToRoot?: boolean;
  targetId?: string;
  requestCode?: number;
  props?: { [x: string]: any };
  options?: NavigationItem;
}

export type NavigationInterceptor = (
  action: string,
  from?: string,
  to?: string,
  extras?: Extras
) => boolean;

export interface Layout {
  [x: string]: {};
}

export interface Screen extends Layout {
  screen: {
    moduleName: string;
    props?: { [x: string]: any };
    options?: NavigationItem;
  };
}

export interface Stack extends Layout {
  stack: {
    children: Layout[];
    options?: {};
  };
}

export interface Tabs extends Layout {
  tabs: {
    children: Layout[];
    options?: {
      selectedIndex?: number;
      tabBarModuleName?: string;
      sizeIndeterminate?: boolean;
    };
  };
}

export interface Drawer extends Layout {
  drawer: {
    children: [Layout, Layout];
    options?: {
      maxDrawerWidth?: number;
      minDrawerMargin?: number;
      menuInteractive?: boolean;
    };
  };
}

EventEmitter.addListener(EVENT_DID_SET_ROOT, _ => {
  if (didSetRootCallback) {
    didSetRootCallback();
  }
});

EventEmitter.addListener(EVENT_WILL_SET_ROOT, _ => {
  if (willSetRootCallback) {
    willSetRootCallback();
  }
});

EventEmitter.addListener(EVENT_SWITCH_TAB, event => {
  Navigator.dispatch(event[KEY_SCENE_ID], 'switchTab', {
    index: event[KEY_INDEX],
    moduleName: event[KEY_MODULE_NAME],
  });
});

export class Navigator {
  static RESULT_OK: -1 = NavigationModule.RESULT_OK;
  static RESULT_CANCEL: 0 = NavigationModule.RESULT_CANCEL;

  static get(sceneId: string): Navigator {
    return store.getNavigator(sceneId) || new Navigator(sceneId);
  }

  static async current(): Promise<Navigator> {
    const route = await Navigator.currentRoute();
    return Navigator.get(route.sceneId);
  }

  static async currentRoute(): Promise<Route> {
    await Navigator.foreground();
    return await NavigationModule.currentRoute();
  }

  static async routeGraph(): Promise<RouteGraph[]> {
    await Navigator.foreground();
    return await NavigationModule.routeGraph();
  }

  static setRoot(layout: Layout, sticky = false) {
    const pureLayout = bindBarButtonItemClickEvent(layout, {
      inLayout: true,
      navigatorFactory: (sceneId: string) => {
        return new Navigator(sceneId);
      },
    });
    NavigationModule.setRoot(pureLayout, sticky);
  }

  static setRootLayoutUpdateListener(willSetRoot = () => {}, didSetRoot = () => {}) {
    willSetRootCallback = willSetRoot;
    didSetRootCallback = didSetRoot;
  }

  static async dispatch(sceneId: string, action: string, params: Params = {}): Promise<void> {
    await Navigator.foreground();
    const navigator = Navigator.get(sceneId);
    if (
      !intercept ||
      !intercept(action, navigator.moduleName, params.moduleName, {
        sceneId,
        index: params.index,
      })
    ) {
      NavigationModule.dispatch(sceneId, action, params);
    }
  }

  static setInterceptor(interceptor: NavigationInterceptor) {
    intercept = interceptor;
  }

  static reload() {
    NavigationModule.reload();
  }

  static delay(ms: number): Promise<{}> {
    return NavigationModule.delay(ms);
  }

  static foreground(): Promise<void> {
    if (Platform.OS === 'android') {
      return NavigationModule.foreground();
    } else {
      return Promise.resolve();
    }
  }

  constructor(public sceneId: string, public moduleName?: string) {
    this.sceneId = sceneId;
    this.moduleName = moduleName;
    this.dispatch = this.dispatch.bind(this);
    this.setParams = this.setParams.bind(this);

    this.push = this.push.bind(this);
    this.pop = this.pop.bind(this);
    this.popTo = this.popTo.bind(this);
    this.popToRoot = this.popToRoot.bind(this);
    this.replace = this.replace.bind(this);
    this.replaceToRoot = this.replaceToRoot.bind(this);
    this.isStackRoot = this.isStackRoot.bind(this);

    this.present = this.present.bind(this);
    this.dismiss = this.dismiss.bind(this);
    this.showModal = this.showModal.bind(this);
    this.hideModal = this.hideModal.bind(this);
    this.setResult = this.setResult.bind(this);

    this.toggleMenu = this.toggleMenu.bind(this);
    this.openMenu = this.openMenu.bind(this);
    this.closeMenu = this.closeMenu.bind(this);
  }

  state: { params: { readonly [x: string]: any } } = { params: {} };

  setParams(params: { [x: string]: any }) {
    this.state.params = { ...this.state.params, ...params };
  }

  dispatch(action: string, params: Params = {}) {
    Navigator.dispatch(this.sceneId, action, params);
  }

  push(
    moduleName: string,
    props: { [x: string]: any } = {},
    options: NavigationItem = {},
    animated = true
  ) {
    this.dispatch('push', { moduleName, props, options, animated });
  }

  pushLayout(layout: Layout, animated = true) {
    this.dispatch('pushLayout', { layout, animated });
  }

  pop(animated = true) {
    this.dispatch('pop', { animated });
  }

  popTo(sceneId: string, animated = true) {
    this.dispatch('popTo', { animated, targetId: sceneId });
  }

  popToRoot(animated = true) {
    this.dispatch('popToRoot', { animated });
  }

  replace(moduleName: string, props: { [x: string]: any } = {}, options: NavigationItem = {}) {
    this.dispatch('replace', { moduleName, props, options, animated: true });
  }

  replaceToRoot(
    moduleName: string,
    props: { [x: string]: any } = {},
    options: NavigationItem = {}
  ) {
    this.dispatch('replaceToRoot', { moduleName, props, options, animated: true });
  }

  async isStackRoot(): Promise<boolean> {
    await Navigator.foreground();
    return NavigationModule.isNavigationRoot(this.sceneId);
  }

  present(
    moduleName: string,
    requestCode = 0,
    props: { [x: string]: any } = {},
    options: NavigationItem = {},
    animated = true
  ) {
    this.dispatch('present', {
      moduleName,
      props,
      options,
      requestCode,
      animated,
    });
  }

  presentLayout(layout: Layout, requestCode = 0, animated = true) {
    this.dispatch('presentLayout', { layout, requestCode, animated });
  }

  dismiss(animated = true) {
    this.dispatch('dismiss', { animated });
  }

  showModal(
    moduleName: string,
    requestCode = 0,
    props: { [x: string]: any } = {},
    options: NavigationItem = {}
  ) {
    this.dispatch('showModal', {
      moduleName,
      props,
      options,
      requestCode,
    });
  }

  showModalLayout(layout: Layout, requestCode = 0) {
    this.dispatch('showModalLayout', { layout, requestCode });
  }

  hideModal() {
    this.dispatch('hideModal');
  }

  setResult(resultCode: number, data: { [x: string]: any } = {}): void {
    NavigationModule.setResult(this.sceneId, resultCode, data);
  }

  switchTab(index: number, popToRoot: boolean = false) {
    this.dispatch('switchTab', { index, popToRoot });
  }

  toggleMenu() {
    this.dispatch('toggleMenu');
  }

  openMenu() {
    this.dispatch('openMenu');
  }

  closeMenu() {
    this.dispatch('closeMenu');
  }

  signalFirstRenderComplete(): void {
    NavigationModule.signalFirstRenderComplete(this.sceneId);
  }
}
