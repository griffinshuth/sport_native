package com.sportdream.NativeUI;

import android.support.annotation.Nullable;
import android.view.View;
import android.widget.TextView;

import com.baidu.mapapi.map.BaiduMap;
import com.baidu.mapapi.map.BitmapDescriptor;
import com.baidu.mapapi.map.BitmapDescriptorFactory;
import com.baidu.mapapi.map.GroundOverlayOptions;
import com.baidu.mapapi.map.InfoWindow;
import com.baidu.mapapi.map.MapPoi;
import com.baidu.mapapi.map.MapStatus;
import com.baidu.mapapi.map.MapStatusUpdate;
import com.baidu.mapapi.map.MapStatusUpdateFactory;
import com.baidu.mapapi.map.MapView;
import com.baidu.mapapi.map.Marker;
import com.baidu.mapapi.map.MarkerOptions;
import com.baidu.mapapi.map.Overlay;
import com.baidu.mapapi.map.OverlayOptions;
import com.baidu.mapapi.map.Polygon;
import com.baidu.mapapi.map.PolygonOptions;
import com.baidu.mapapi.map.Stroke;
import com.baidu.mapapi.model.LatLng;
import com.baidu.mapapi.model.LatLngBounds;
import com.baidu.mapapi.utils.SpatialRelationUtil;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.annotations.ReactProp;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.sportdream.R;

/**
 * Created by lili on 2017/9/19.
 */


public class BaiduMapViewManager extends ViewGroupManager<MapView> {

    enum MarkerType{
        normal,
        location,
        basketballcourt
    }
    private ThemedReactContext mReactContext;
    private HashMap<String,Marker> mMarkerMap = new HashMap<>();
    private HashMap<String,List<Marker>> mMarkersMap = new HashMap<>();
    private HashMap<String,List<Overlay>> mCourtsMap = new HashMap<>();
    private TextView mMarkerText;

    private LatLng getLatLngFromOption(ReadableMap option){
        double latitude = option.getDouble("latitude");
        double longitude = option.getDouble("longitude");
        return new LatLng(latitude,longitude);
    }

    private void updateMarker(Marker marker,ReadableMap option){
        LatLng position = getLatLngFromOption(option);
        marker.setPosition(position);
        marker.setTitle(option.getString("title"));
    }

    private Marker addMarker(MapView mapView,ReadableMap option,MarkerType markerType){
        BitmapDescriptor bitmap;
        if(markerType == MarkerType.normal){
            bitmap = BitmapDescriptorFactory.fromResource(R.mipmap.icon_gcoding);
        }else if(markerType == MarkerType.location){
            bitmap = BitmapDescriptorFactory.fromResource(R.mipmap.location);
        }else if(markerType == MarkerType.basketballcourt){
            bitmap = BitmapDescriptorFactory.fromResource(R.mipmap.basketballcourticon);
        }else{
            bitmap = BitmapDescriptorFactory.fromResource(R.mipmap.icon_gcoding);
        }
        LatLng position = getLatLngFromOption(option);
        MarkerOptions overlayOptions = new MarkerOptions().icon(bitmap).position(position).title(option.getString("title"));
        overlayOptions.animateType(MarkerOptions.MarkerAnimateType.drop);
        Marker marker = (Marker)mapView.getMap().addOverlay(overlayOptions);
        return marker;
    }

    private Overlay addCourt(MapView mapView,ReadableMap option){
        List<LatLng> pts = new ArrayList<LatLng>();
        ReadableArray points = option.getArray("points");

        LatLng southwest = getLatLngFromOption(points.getMap(0));
        LatLng northeast = getLatLngFromOption(points.getMap(1));
        LatLngBounds bounds = new LatLngBounds.Builder().include(northeast)
                .include(southwest).build();

        BitmapDescriptor bdGround = BitmapDescriptorFactory
                .fromResource(R.drawable.basketballcourt);
        OverlayOptions ooGround = new GroundOverlayOptions()
                .positionFromBounds(bounds).image(bdGround).transparency(0.8f);

        Overlay overlay = mapView.getMap().addOverlay(ooGround);
        return overlay;
    }

    public String getName(){
        return "BaiduMapView";
    }

    public MapView createViewInstance(ThemedReactContext context){
        mReactContext = context;
        MapView mapView = new MapView(context);
        setListeners(mapView);
        return mapView;
    }


    @ReactProp(name="zoom")
    public void setZoom(MapView mapView,float zoom){
        MapStatus mapStatus = new MapStatus.Builder().zoom(zoom).build();
        MapStatusUpdate mapStatusUpdate = MapStatusUpdateFactory.newMapStatus(mapStatus);
        mapView.getMap().animateMapStatus(mapStatusUpdate);
    }

    @ReactProp(name="center")
    public void setCenter(MapView mapView, ReadableMap position){
        if(position  != null){
            double latitude = position.getDouble("latitude");
            double longitude = position.getDouble("longitude");
            LatLng point = new LatLng(latitude,longitude);
            MapStatus.Builder builder = new MapStatus.Builder();
            builder.target(point);
            mapView.getMap().animateMapStatus(MapStatusUpdateFactory.newMapStatus(builder.build()));
        }
    }

    @ReactProp(name="marker")
    public void setMarker(MapView mapView,ReadableMap option){
        if(option != null){
            String key = "marker_"+mapView.getId();
            Marker marker = mMarkerMap.get(key);
            if(marker != null){
                updateMarker(marker,option);
            }else{
                marker = addMarker(mapView,option,MarkerType.location);
                mMarkerMap.put(key,marker);
            }
        }
    }

    @ReactProp(name="markers")
    public void setMarkers(MapView mapView, ReadableArray options){
        String key = "markers_"+mapView.getId();
        List<Marker> markers = mMarkersMap.get(key);
        if(markers == null){
            markers = new ArrayList<>();
        }
        for(int i=0;i<options.size();i++){
            ReadableMap option = options.getMap(i);
            if(markers.size() > i){
                updateMarker(markers.get(i),option);
            }else{
                int type = option.getInt("icontype");
                markers.add(i,addMarker(mapView,option,MarkerType.values()[type]));
            }
        }
        if(options.size() < markers.size()){
            int start  = markers.size() -1;
            int end = options.size();
            for(int i=start;i>=end;i--){
                markers.get(i).remove();
                markers.remove(i);
            }
        }
        mMarkersMap.put(key,markers);
    }

    @ReactProp(name="basketballCourt")
    public void setBasketballCourt(MapView mapView,ReadableArray options){
        String key = "basketballCourt_"+mapView.getId();
        List<Overlay> markers = mCourtsMap.get(key);
        if(markers == null){
            markers = new ArrayList<>();
        }else{
            //删除以前存储的球场数据
            int len = markers.size();
            for(int i=0;i<len;i++){
                markers.get(i).remove();
                markers.remove(i);
            }
        }

        for(int j=0;j<options.size();j++){
            ReadableMap option = options.getMap(j);
            markers.add(j,addCourt(mapView,option));
        }

        mCourtsMap.put(key,markers);
    }

    private void setListeners(final MapView mapView){
        final BaiduMap map = mapView.getMap();

        if(mMarkerText == null){
            mMarkerText = new TextView(mapView.getContext());
            mMarkerText.setBackgroundResource(R.drawable.popup);
            mMarkerText.setPadding(32,32,32,32);
        }
        map.setOnMapStatusChangeListener(new BaiduMap.OnMapStatusChangeListener(){
            private WritableMap getEventParams(MapStatus mapStatus){
                WritableMap writableMap = Arguments.createMap();
                WritableMap target = Arguments.createMap();
                target.putDouble("latitude",mapStatus.target.latitude);
                target.putDouble("longitude",mapStatus.target.longitude);
                writableMap.putMap("target",target);
                writableMap.putDouble("zoom",mapStatus.zoom);
                writableMap.putDouble("overlook",mapStatus.overlook);
                return writableMap;
            }
            @Override
            public void onMapStatusChangeStart(MapStatus mapStatus){
                sendEvent(mapView,"onMapStatusChangeStart",getEventParams(mapStatus));
            }
            @Override
            public void onMapStatusChangeStart(MapStatus mapStatus,int reason){
                sendEvent(mapView,"onMapStatusChangeStart",getEventParams(mapStatus));
            }
            @Override
            public void onMapStatusChange(MapStatus mapStatus) {
                sendEvent(mapView, "onMapStatusChange", getEventParams(mapStatus));
            }

            @Override
            public void onMapStatusChangeFinish(MapStatus mapStatus) {
                if(mMarkerText.getVisibility() != View.GONE){
                    mMarkerText.setVisibility(View.GONE);
                }
                sendEvent(mapView, "onMapStatusChangeFinish", getEventParams(mapStatus));
            }
        });

        map.setOnMapLoadedCallback(new BaiduMap.OnMapLoadedCallback(){
            @Override
            public void onMapLoaded(){
                sendEvent(mapView,"onMapLoaded",null);
            }
        });

        map.setOnMapClickListener(new BaiduMap.OnMapClickListener(){
            @Override
            public void onMapClick(LatLng latLng){
                mapView.getMap().hideInfoWindow();
                WritableMap writableMap = Arguments.createMap();
                writableMap.putDouble("latitude",latLng.latitude);
                writableMap.putDouble("longitude",latLng.longitude);
                sendEvent(mapView,"onMapClick",writableMap);
            }

            @Override
            public boolean onMapPoiClick(MapPoi mapPoi){
                WritableMap writableMap = Arguments.createMap();
                writableMap.putString("name",mapPoi.getName());
                writableMap.putString("uid",mapPoi.getUid());
                writableMap.putDouble("latitude",mapPoi.getPosition().latitude);
                writableMap.putDouble("longitude",mapPoi.getPosition().longitude);
                sendEvent(mapView,"onMapPoiClick",writableMap);
                return true;
            }
        });

        map.setOnMapDoubleClickListener(new BaiduMap.OnMapDoubleClickListener(){
            @Override
            public void onMapDoubleClick(LatLng latLng){
                WritableMap writableMap = Arguments.createMap();
                writableMap.putDouble("latitude",latLng.latitude);
                writableMap.putDouble("longitude",latLng.longitude);
                sendEvent(mapView,"onMapDoubleClick",writableMap);
            }
        });

        map.setOnMarkerClickListener(new BaiduMap.OnMarkerClickListener(){
            @Override
            public boolean onMarkerClick(Marker marker){
                if(marker.getTitle().length()>0){
                    mMarkerText.setText(marker.getTitle());
                    InfoWindow infoWindow = new InfoWindow(mMarkerText,marker.getPosition(),-80);
                    mMarkerText.setVisibility(View.GONE);
                    mapView.getMap().showInfoWindow(infoWindow);
                }else{
                    mapView.getMap().hideInfoWindow();
                }

                WritableMap writableMap = Arguments.createMap();
                WritableMap position = Arguments.createMap();
                position.putDouble("latitude",marker.getPosition().latitude);
                position.putDouble("longitude",marker.getPosition().longitude);
                writableMap.putMap("position",position);
                writableMap.putString("title",marker.getTitle());
                sendEvent(mapView,"onMarkerClick",writableMap);
                return true;
            }
        });

    }

    private void sendEvent(MapView mapView, String eventName, @Nullable WritableMap params){
        WritableMap event = Arguments.createMap();
        event.putMap("params",params);
        event.putString("type",eventName);
        mReactContext.getJSModule(RCTEventEmitter.class)
                .receiveEvent(mapView.getId(),"topChange",event);
    }


}



































