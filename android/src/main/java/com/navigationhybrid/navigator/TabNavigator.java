package com.navigationhybrid.navigator;

import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.navigationhybrid.HybridFragment;
import com.navigationhybrid.ReactBridgeManager;
import com.navigationhybrid.ReactTabBarFragment;
import com.navigationhybrid.ReactTabBarProvider;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import me.listenzz.navigation.AwesomeFragment;
import me.listenzz.navigation.NavigationFragment;
import me.listenzz.navigation.TabBarFragment;

public class TabNavigator implements Navigator {

    private List<String> supportActions = Collections.singletonList("switchTab");

    @Override
    @NonNull
    public String name() {
        return "tabs";
    }

    @Override
    @NonNull
    public List<String> supportActions() {
        return supportActions;
    }

    @Override
    @Nullable
    public AwesomeFragment createFragment(@NonNull ReadableMap layout) {
        if (layout.hasKey(name())) {
            ReadableMap tabs = layout.getMap(name());
            if (tabs == null) {
                throw new IllegalArgumentException("tabs should be an object");
            }
            ReadableArray children = tabs.getArray("children");

            if (children == null) {
                throw new IllegalArgumentException("children is required and it is an array");
            }

            List<AwesomeFragment> fragments = new ArrayList<>();

            for (int i = 0, size = children.size(); i < size; i++) {
                ReadableMap tab = children.getMap(i);
                AwesomeFragment awesomeFragment = getReactBridgeManager().createFragment(tab);
                if (awesomeFragment != null) {
                    fragments.add(awesomeFragment);
                }
            }

            if (fragments.size() > 0) {
                ReactTabBarFragment tabBarFragment = new ReactTabBarFragment();
                tabBarFragment.setChildFragments(fragments);
                Bundle bundle = new Bundle();
                if (tabs.hasKey("options")) {
                    ReadableMap options = tabs.getMap("options");
                    if (options == null) {
                        throw new IllegalArgumentException("options should be an object");
                    }

                    if (options.hasKey("selectedIndex")) {
                        int selectedIndex = options.getInt("selectedIndex");
                        tabBarFragment.setSelectedIndex(selectedIndex);
                        bundle.putInt("selectedIndex", selectedIndex);
                    }

                    if (options.hasKey("tabBarModuleName")) {
                        String tabBarModuleName = options.getString("tabBarModuleName");
                        bundle.putString("tabBarModuleName", tabBarModuleName);
                        tabBarFragment.setTabBarProvider(new ReactTabBarProvider());
                    }

                    if (options.hasKey("sizeIndeterminate")) {
                        boolean sizeIndeterminate = options.getBoolean("sizeIndeterminate");
                        bundle.putBoolean("sizeIndeterminate", sizeIndeterminate);
                    }
                }

                tabBarFragment.setOptions(bundle);
                return tabBarFragment;
            } else {
                throw new IllegalArgumentException("tabs layout should has a child at least");
            }
        }
        return null;
    }

    @Override
    public boolean buildRouteGraph(@NonNull AwesomeFragment fragment, @NonNull ArrayList<Bundle> root, @NonNull ArrayList<Bundle> modal) {
        if (fragment instanceof TabBarFragment && fragment.isAdded()) {
            TabBarFragment tabs = (TabBarFragment) fragment;
            ArrayList<Bundle> children = new ArrayList<>();
            List<AwesomeFragment> fragments = tabs.getChildFragments();
            for (int i = 0; i < fragments.size(); i++) {
                AwesomeFragment child = fragments.get(i);
                getReactBridgeManager().buildRouteGraph(child, children, modal);
            }
            Bundle graph = new Bundle();
            graph.putString("layout", name());
            graph.putString("sceneId", fragment.getSceneId());
            graph.putParcelableArrayList("children", children);
            graph.putString("mode", Navigator.Util.getMode(fragment));
            graph.putInt("selectedIndex", tabs.getSelectedIndex());
            root.add(graph);
            return true;
        }
        return false;
    }

    @Override
    public HybridFragment primaryFragment(@NonNull AwesomeFragment fragment) {
        if (fragment instanceof TabBarFragment && fragment.isAdded()) {
            TabBarFragment tabs = (TabBarFragment) fragment;
            return getReactBridgeManager().primaryFragment(tabs.getSelectedFragment());
        }
        return null;
    }

    @Override
    public void handleNavigation(@NonNull AwesomeFragment target, @NonNull String action, @NonNull ReadableMap extras) {
        switch (action) {
            case "switchTab":
                TabBarFragment tabBarFragment = target.getTabBarFragment();
                int index = extras.getInt("index");

                if (tabBarFragment != null) {
                    boolean popToRoot = extras.hasKey("popToRoot") && extras.getBoolean("popToRoot");
                    if (popToRoot) {
                        AwesomeFragment presented = tabBarFragment.getPresentedFragment();
                        if (presented != null) {
                            presented.dismissFragment();
                        }

                        if (index != tabBarFragment.getSelectedIndex()) {
                            NavigationFragment nav = target.getNavigationFragment();
                            if (nav != null) {
                                nav.popToRootFragment(false);
                            }
                        }
                    }

                    if (tabBarFragment instanceof ReactTabBarFragment) {
                        ReactTabBarFragment reactTabBarFragment = (ReactTabBarFragment) tabBarFragment;
                        reactTabBarFragment.setIntercepted(false);
                        tabBarFragment.setSelectedIndex(index);
                        reactTabBarFragment.setIntercepted(true);
                    } else {
                        tabBarFragment.setSelectedIndex(index);
                    }
                }
                break;
        }
    }

    private ReactBridgeManager getReactBridgeManager() {
        return ReactBridgeManager.get();
    }

}
