import { AppRegistry, EmitterSubscription, ComponentProvider } from 'react-native';
import React from 'react';
import { Navigator } from './Navigator';
import {
  EventEmitter,
  NavigationModule,
  EVENT_NAVIGATION,
  KEY_SCENE_ID,
  KEY_ON,
  ON_BAR_BUTTON_ITEM_CLICK,
  ON_COMPONENT_RESULT,
  ON_COMPONENT_DISAPPEAR,
  ON_COMPONENT_APPEAR,
  ON_DIALOG_BACK_PRESSED,
  ON_COMPONENT_MOUNT,
  KEY_REQUEST_CODE,
  KEY_RESULT_CODE,
  KEY_RESULT_DATA,
  KEY_ACTION,
} from './NavigationModule';
import { Garden, NavigationItem } from './Garden';
import { router, RouteConfig } from './router';
import store from './store';
import { bindBarButtonItemClickEvent, removeBarButtonItemClickEvent } from './utils';

export interface NavigationType {
  navigationItem?: NavigationItem;
}

export interface Navigation {
  onBarButtonItemClick?(action: string): void;
  onComponentResult?(requestCode: number, resultCode: number, data: { [x: string]: any }): void;
  componentDidAppear?(): void;
  componentDidDisappear?(): void;
  onBackPressed?(): void;
}

export interface Props {
  navigator: Navigator;
  garden: Garden;
}

function getDisplayName(WrappedComponent: React.ComponentType) {
  return WrappedComponent.displayName || WrappedComponent.name || 'Component';
}

function withNavigator(moduleName: string) {
  return function(
    WrappedComponent: React.ComponentType<{
      ref?: React.RefObject<React.Component>;
      navigator?: Navigator;
      garden?: Garden;
    }>
  ) {
    return class extends React.Component<{ sceneId?: string }> {
      static displayName = `WithNavigator(${getDisplayName(WrappedComponent)})`;

      private subscription?: EmitterSubscription;
      private navigator?: Navigator;
      private garden?: Garden;
      private navigationRef?: React.RefObject<React.Component>;

      constructor(props: { sceneId?: string }) {
        super(props);
        if (props.sceneId) {
          this.navigationRef = React.createRef();
          this.navigator =
            store.getNavigator(props.sceneId) || new Navigator(props.sceneId, moduleName);
          store.addNavigator(props.sceneId, this.navigator);
          this.garden = new Garden(props.sceneId);
        }
      }

      componentDidMount() {
        if (this.props.sceneId) {
          this.navigator!.signalFirstRenderComplete();
          this.subscription = EventEmitter.addListener(EVENT_NAVIGATION, data => {
            if (this.props.sceneId !== data[KEY_SCENE_ID]) {
              return;
            }
            const navigation = this.navigationRef!.current as Navigation;
            if (!navigation) {
              return;
            }
            switch (data[KEY_ON]) {
              case ON_BAR_BUTTON_ITEM_CLICK:
                if (navigation.onBarButtonItemClick) {
                  navigation.onBarButtonItemClick(data[KEY_ACTION]);
                }
                break;
              case ON_COMPONENT_RESULT:
                if (navigation.onComponentResult) {
                  navigation.onComponentResult(
                    data[KEY_REQUEST_CODE],
                    data[KEY_RESULT_CODE],
                    data[KEY_RESULT_DATA]
                  );
                }
                break;
              case ON_COMPONENT_APPEAR:
                if (navigation.componentDidAppear) {
                  navigation.componentDidAppear();
                }
                break;
              case ON_COMPONENT_DISAPPEAR:
                if (navigation.componentDidDisappear) {
                  navigation.componentDidDisappear();
                }
                break;
              case ON_COMPONENT_MOUNT:
                if (this.navigator) {
                  this.navigator.signalFirstRenderComplete();
                }
                break;
              case ON_DIALOG_BACK_PRESSED:
                if (navigation.onBackPressed) {
                  navigation.onBackPressed();
                }
                break;
              default:
                throw new Error(`event ${data[KEY_ON]} has not been processed yet.`);
            }
          });
        }
      }

      componentWillUnmount() {
        if (this.props.sceneId) {
          removeBarButtonItemClickEvent(this.props.sceneId);
          store.removeNavigator(this.props.sceneId);
          this.subscription!.remove();
        }
      }

      render() {
        return (
          <WrappedComponent
            {...this.props}
            ref={this.navigationRef}
            garden={this.garden}
            navigator={this.navigator}
          />
        );
      }
    };
  };
}

export type HigherOrderComponent = (WrappedComponent: React.ComponentType) => React.ComponentType;
let wrap: HigherOrderComponent | undefined;

export class ReactRegistry {
  static registerEnded: boolean;
  static startRegisterComponent(hoc?: HigherOrderComponent) {
    console.info('begin register react component');
    router.clear();
    store.clear();
    wrap = hoc;
    ReactRegistry.registerEnded = false;
    NavigationModule.startRegisterReactComponent();
  }

  static endRegisterComponent() {
    if (ReactRegistry.registerEnded) {
      console.warn(`Please don't call ReactRegistry#endRegisterComponent multiple times.`);
      return;
    }
    ReactRegistry.registerEnded = true;
    NavigationModule.endRegisterReactComponent();
    console.info('end register react component');
  }

  static registerComponent(
    appKey: string,
    getComponentFunc: ComponentProvider,
    routeConfig?: RouteConfig
  ) {
    if (routeConfig) {
      router.addRouteConfig(appKey, routeConfig);
    }

    const WrappedComponent = getComponentFunc();
    const navigation = WrappedComponent as NavigationType;

    // build static options
    let options: any = navigation.navigationItem
      ? bindBarButtonItemClickEvent(navigation.navigationItem)
      : {};

    if (options['tabItem'] && options['tabItem']['selectedIcon']) {
      options['tabItem']['unselectedIcon'] = options['tabItem']['icon'];
      options['tabItem']['icon'] = options['tabItem']['selectedIcon'];
    }

    NavigationModule.registerReactComponent(appKey, options);

    let RootComponent: React.ComponentType;
    if (wrap) {
      RootComponent = wrap(withNavigator(appKey)(WrappedComponent));
    } else {
      RootComponent = withNavigator(appKey)(WrappedComponent);
    }
    AppRegistry.registerComponent(appKey, () => RootComponent);
  }
}
