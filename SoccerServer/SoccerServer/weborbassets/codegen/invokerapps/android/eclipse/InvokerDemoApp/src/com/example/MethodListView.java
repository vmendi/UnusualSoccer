package com.example;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.widget.*;

import controllers.MethodListController;

/**
 * Method list view class. Makes visual presentation of methods.
 *
 * @author Yuri Samsoniuk
 */
public class MethodListView extends Activity {
    /**
     * Controller for managing events
     */
    private MethodListController controller;

    /**
     * Called when the activity is first created.
     */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        controller = new MethodListController(this);

        this.setTitle("Methods View");
        setContentView(R.layout.methods_list_layout);
        ListView methodsList = (ListView) findViewById(R.id.methods_list);
        methodsList.addHeaderView(controller.getHeaderView());
        methodsList.setAdapter(controller.getListEvent());
        methodsList.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            public void onItemClick(AdapterView<?> adapterView, View view, int i, long l) {
                if (i != 0) {
                    controller.itemClickedEvent(i - 1);
                }
            }
        });
        findViewById(R.id.connection_properties_button).setOnClickListener(new View.OnClickListener() {
            public void onClick(View view) {
                controller.configureConnectionsRequest();
            }
        });
    }
}
