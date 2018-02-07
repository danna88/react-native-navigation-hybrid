package com.navigationhybrid;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Shader;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.Gravity;

import me.listenzz.navigation.BarStyle;
import me.listenzz.navigation.DrawableUtils;
import me.listenzz.navigation.Style;


/**
 * Created by Listen on 2018/1/9.
 */

public class GlobalStyle {

    private static final String TAG = "ReactNative";

    private Bundle options;

    public void setOptions(Bundle options) {
        this.options = options;
    }

    public Bundle getOptions() {
        return options;
    }

    public void inflateStyle(Context context, Style style) {
        if (options == null) {
            Log.w(TAG, "style options is null");
            return;
        }

        Log.i(TAG, "begin custom global style");

        // screenBackgroundColor
        String screenBackgroundColor = options.getString("screenBackgroundColor");
        if (screenBackgroundColor != null) {
            style.setScreenBackgroundColor(Color.parseColor(screenBackgroundColor));
        }

        // topBarStyle
        String topBarStyle = options.getString("topBarStyle");
        if (topBarStyle != null) {
            style.setToolbarStyle(topBarStyle.equals("dark-content") ? BarStyle.DarkContent : BarStyle.LightContent);
        }

        // topBarBackgroundColor
        String topBarBackgroundColor = options.getString("topBarBackgroundColor");
        if (topBarBackgroundColor != null) {
            style.setToolbarBackgroundColor(Color.parseColor(topBarBackgroundColor));
        } else {
            if (style.getToolbarStyle() == BarStyle.LightContent) {
                style.setToolbarBackgroundColor(Color.BLACK);
            } else {
                style.setToolbarBackgroundColor(Color.WHITE);
            }
        }

        // statusBarColor
        String statusBarColor = options.getString("statusBarColor");
        if (statusBarColor != null) {
            style.setStatusBarColor(Color.parseColor(statusBarColor));
        } else {
            style.setStatusBarColor(style.getToolbarBackgroundColor());
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            // elevation
            double elevation = options.getDouble("elevation", -1);
            if (elevation != -1) {
                style.setElevation((int)elevation);
            }
        } else {
            // shadow
            Bundle shadowImage = options.getBundle("shadowImage");
            if (shadowImage != null) {
                Bundle image = shadowImage.getBundle("image");
                String color = shadowImage.getString("color");
                Drawable drawable = null;
                if (image != null) {
                    String uri = image.getString("uri");
                    if (uri != null) {
                        drawable = DrawableUtils.fromUri(context, uri);
                        if (drawable instanceof BitmapDrawable) {
                            BitmapDrawable bitmapDrawable = (BitmapDrawable) drawable;
                            bitmapDrawable.setTileModeX(Shader.TileMode.REPEAT);
                        }
                    }
                } else if (color != null) {
                    drawable = new ColorDrawable(Color.parseColor(color));
                }
                style.setShadow(drawable);
            }
        }

        // topBarTintColor
        String topBarTintColor = options.getString("topBarTintColor");
        if (topBarTintColor != null) {
            style.setToolbarTintColor(Color.parseColor(topBarTintColor));
        }

        // titleTextColor
        String titleTextColor = options.getString("titleTextColor");
        if (titleTextColor != null) {
            style.setTitleTextColor(Color.parseColor(titleTextColor));
        }

        // titleTextSize
        int titleTextSize = options.getInt("titleTextSize", -1);
        if (titleTextSize != -1) {
            style.setTitleTextSize(titleTextSize);
        }

        // titleAlignment
        String titleAlignment = options.getString("titleAlignment");
        if (titleAlignment != null) {
            style.setTitleGravity(titleAlignment.equals("center") ? Gravity.CENTER : Gravity.START);
        }

        // barButtonItemTintColor
        String barButtonItemTintColor = options.getString("barButtonItemTintColor");
        if (barButtonItemTintColor != null) {
            style.setToolbarButtonTintColor(Color.parseColor(barButtonItemTintColor));
        }

        // barButtonItemTextSize
        int barButtonItemTextSize = options.getInt("barButtonItemTextSize", -1);
        if (barButtonItemTextSize != -1) {
            style.setToolbarButtonTextSize(barButtonItemTextSize);
        }

        // backIcon
        Bundle backIcon = options.getBundle("backIcon");
        if (backIcon != null) {
            String uri = backIcon.getString("uri");
            if (uri != null) {
                Drawable drawable = DrawableUtils.fromUri(context, uri);
                //drawable.setColorFilter(style.getToolbarTintColor(), PorterDuff.Mode.SRC_ATOP);
                style.setBackIcon(drawable);
            }
        }

        // --------- tabBar ------------
        // -----------------------------

        // tabBarBackgroundColor
        String bottomBarBackgroundColor = options.getString("bottomBarBackgroundColor");
        if (bottomBarBackgroundColor != null) {
            style.setBottomBarBackgroundColor(bottomBarBackgroundColor);
        }

        String bottomBarButtonItemTintColor = options.getString("bottomBarButtonItemTintColor");
        if (bottomBarButtonItemTintColor != null) {
            style.setBottomBarActiveColor(bottomBarButtonItemTintColor);
        }

        // bottomBarShadowImage
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            Bundle shadowImage = options.getBundle("bottomBarShadowImage");
            if (shadowImage != null) {
                Bundle image = shadowImage.getBundle("image");
                String color = shadowImage.getString("color");
                Drawable drawable = null;
                if (image != null) {
                    String uri = image.getString("uri");
                    if (uri != null) {
                        drawable = DrawableUtils.fromUri(context, uri);
                        if (drawable instanceof BitmapDrawable) {
                            BitmapDrawable bitmapDrawable = (BitmapDrawable) drawable;
                            bitmapDrawable.setTileModeX(Shader.TileMode.REPEAT);
                        }
                    }
                } else if (color != null) {
                    drawable = new ColorDrawable(Color.parseColor(color));
                }
                style.setBottomBarShadow(drawable);
            }
        }
    }

}
