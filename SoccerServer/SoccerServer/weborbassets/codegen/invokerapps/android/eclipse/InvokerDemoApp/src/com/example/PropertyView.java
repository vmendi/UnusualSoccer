package com.example;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.widget.EditText;
import controllers.PropertyController;

/**
 * Properties view.
 * @author Yuri Samsoniuk
 */
public class PropertyView extends Activity {
    /**
     * Properties managing controller
     */
    PropertyController controller;
    /**
     * View with WebORB endpoint URL
     */
    EditText weborbUrlView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        controller = new PropertyController(this);

        setTitle("Connection Properties");
        setContentView(R.layout.property_layout);

        weborbUrlView = (EditText) findViewById(R.id.url);
        weborbUrlView.setText(controller.getWebORBURL());

        findViewById(R.id.accept_button).setOnClickListener(new View.OnClickListener() {
            public void onClick(View view) {
                controller.accept(weborbUrlView.getText().toString());
            }
        });

        findViewById(R.id.test_connection_button).setOnClickListener(new View.OnClickListener() {
            public void onClick(View view) {
                controller.testConnection(weborbUrlView.getText().toString());
            }
        });
    }
}

