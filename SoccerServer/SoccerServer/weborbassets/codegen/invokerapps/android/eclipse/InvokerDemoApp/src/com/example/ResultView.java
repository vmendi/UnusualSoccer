package com.example;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.widget.TableLayout;
import controllers.ResultController;

import java.util.ArrayList;

/**
 * Method invocation result view. Displays element of result.
 *
 * @author Yuri Samsoniuk
 */
public class ResultView extends Activity {
    /**
     * Controller for managing events
     */
    private ResultController controller;
    /**
     * Result elements layout
     */
    private TableLayout elementsLayout;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        controller = new ResultController(this);
        setTitle(controller.getTitle());
        setContentView(R.layout.result_layout);

        composeLayout();

        findViewById(R.id.returnButton).setOnClickListener(new View.OnClickListener() {
            public void onClick(View view) {
                finish();
            }
        });
    }

    /**
     * Composes result element's views
     */
    private void composeLayout() {
        elementsLayout = (TableLayout) findViewById(R.id.result_items_layout);
        ArrayList<View> views = controller.getViewList();
        for (View view : views) {
            elementsLayout.addView(view);
        }
    }
}
