package com.navigationhybrid;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.util.HashMap;
import java.util.Map;


public class HBDEventEmitter extends ReactContextBaseJavaModule {

    public static final String KEY_REQUEST_CODE = "request_code";
    public static final String KEY_RESULT_CODE = "result_code";
    public static final String KEY_RESULT_DATA = "data";
    public static final String KEY_SCENE_ID = "scene_id";
    public static final String KEY_MODULE_NAME = "module_name";
    public static final String KEY_INDEX = "index";
    public static final String KEY_ACTION = "action";
    public static final String KEY_ON = "on";

    public static final String ON_COMPONENT_RESULT = "ON_COMPONENT_RESULT";
    public static final String ON_BAR_BUTTON_ITEM_CLICK = "ON_BAR_BUTTON_ITEM_CLICK";
    public static final String ON_COMPONENT_APPEAR = "ON_COMPONENT_APPEAR";
    public static final String ON_COMPONENT_DISAPPEAR = "ON_COMPONENT_DISAPPEAR";
    public static final String ON_DIALOG_BACK_PRESSED = "ON_DIALOG_BACK_PRESSED";

    public static final String EVENT_SWITCH_TAB = "EVENT_SWITCH_TAB";
    public static final String EVENT_DID_SET_ROOT = "EVENT_DID_SET_ROOT";
    public static final String EVENT_WILL_SET_ROOT = "EVENT_WILL_SET_ROOT";
    public static final String EVENT_NAVIGATION = "EVENT_NAVIGATION";

    public HBDEventEmitter(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "HBDEventEmitter";
    }

    @Nullable
    @Override
    public Map<String, Object> getConstants() {
        final Map<String, Object> constants = new HashMap<>();
        constants.put("ON_COMPONENT_RESULT", ON_COMPONENT_RESULT);
        constants.put("ON_BAR_BUTTON_ITEM_CLICK", ON_BAR_BUTTON_ITEM_CLICK);
        constants.put("ON_COMPONENT_APPEAR", ON_COMPONENT_APPEAR);
        constants.put("ON_COMPONENT_DISAPPEAR", ON_COMPONENT_DISAPPEAR);
        constants.put("ON_DIALOG_BACK_PRESSED", ON_DIALOG_BACK_PRESSED);
        constants.put("KEY_REQUEST_CODE", KEY_REQUEST_CODE);
        constants.put("KEY_RESULT_CODE", KEY_RESULT_CODE);
        constants.put("KEY_RESULT_DATA", KEY_RESULT_DATA);
        constants.put("KEY_SCENE_ID", KEY_SCENE_ID);
        constants.put("KEY_MODULE_NAME", KEY_MODULE_NAME);
        constants.put("KEY_INDEX", KEY_INDEX);
        constants.put("KEY_ACTION", KEY_ACTION);
        constants.put("KEY_ON", KEY_ON);
        constants.put("EVENT_SWITCH_TAB", EVENT_SWITCH_TAB);
        constants.put("EVENT_NAVIGATION", EVENT_NAVIGATION);
        constants.put("EVENT_DID_SET_ROOT", EVENT_DID_SET_ROOT);
        constants.put("EVENT_WILL_SET_ROOT", EVENT_WILL_SET_ROOT);
        return constants;
    }

    public static void sendEvent(@NonNull String eventName, @NonNull WritableMap params) {
        ReactBridgeManager reactBridgeManager = ReactBridgeManager.get();
        ReactContext reactContext = reactBridgeManager.getCurrentReactContext();
        if (reactContext != null && reactBridgeManager.isReactModuleRegisterCompleted()) {
            reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                    .emit(eventName, params);
        }
    }

}
