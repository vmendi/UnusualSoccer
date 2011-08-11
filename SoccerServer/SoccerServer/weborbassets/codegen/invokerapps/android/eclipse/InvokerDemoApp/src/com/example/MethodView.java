package com.example;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.DatePickerDialog;
import android.app.Dialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.*;

import controllers.MethodController;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * Single method view. Manages display of method arguments and data input dialogs, argument's views clicks.
 *
 * @author Yuri Samsoniuk
 */
public class MethodView extends Activity {
    /**
     * Method argument's views layout
     */
    private TableLayout elementsLayout;
    /**
     * Controller for managing events
     */
    private MethodController controller;
    /**
     * Last time clicked view
     */
    private View selectedView;
    /**
     * Listener invoked by input Date value dialog event
     */
    private DatePickerDialog.OnDateSetListener mDateSetListener =
            new DatePickerDialog.OnDateSetListener() {
                public void onDateSet(DatePicker view, int year,
                                      int monthOfYear, int dayOfMonth) {
                    String date = String.format("%04d/%02d/%02d", year, monthOfYear + 1, dayOfMonth);
                    ((TextView) selectedView.findViewById(R.id.value)).setText(date);
                    selectedView = null;
                }
            };
    /**
     * Listener invoked by input primitives value dialog event
     */
    private DialogInterface.OnClickListener mValueSetListener =
            new DialogInterface.OnClickListener() {
                public void onClick(DialogInterface dialogInterface, int i) {
                    EditText editText = (EditText) ((Dialog) dialogInterface).findViewById(R.id.value);
                    String text = editText.getText().toString();
                    TextView view;
                    if (selectedView instanceof TextView) {
                        view = (TextView) selectedView;
                    } else {
                        view = (TextView) selectedView.findViewById(R.id.value);
                    }
                    view.setText(text);
                    selectedView = null;
                    dialogInterface.dismiss();
                }
            };
    /**
     * Listener invoked on event of view click for input data value
     */
    private final View.OnClickListener mDialogShowListener = new View.OnClickListener() {
        public void onClick(View view) {
            selectedView = view;
            showDialog(controller.getDialogId(view));
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        controller = new MethodController(this);
        setTitle(controller.getTitle());
        setContentView(R.layout.method_layout);
        ((TextView) findViewById(R.id.method_signature)).setText(controller.getMethodSignature());

        composeLayout();

        Button invokeButton = (Button) findViewById(R.id.invokeButton);
        Button cancelButton = (Button) findViewById(R.id.cancelButton);

        invokeButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View view) {
                controller.onMethodInvoke();
            }
        });

        cancelButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View view) {
                controller.cancelMethod();
            }
        });
    }

    @Override
    protected void onPrepareDialog(int id, Dialog dialog) {
        if (selectedView != null) {
            String viewValue;
            String viewName;
            if (selectedView instanceof TextView) {
                viewValue = ((TextView) selectedView).getText().toString();
                viewName = "";
            } else {
                viewValue = ((TextView) selectedView.findViewById(R.id.value)).getText().toString();
                viewName = ((TextView) selectedView.findViewById(R.id.name)).getText().toString();
            }
            switch (id) {
                case MethodController.DATE_DIALOG_ID:
                    String date_format = getApplicationContext().getResources().getString(R.string.date_format);
                    Calendar c = null;
                    if (viewValue.length() != 0) {
                        DateFormat df = new SimpleDateFormat(date_format);
                        try {
                            c = df.getCalendar();
                            c.setTime(df.parse(viewValue));
                        } catch (ParseException e) {
                            c = Calendar.getInstance();
                        }
                    } else {
                        c = Calendar.getInstance();
                    }
                    ((DatePickerDialog) dialog).updateDate(c.get(Calendar.YEAR), c.get(Calendar.MONTH), c.get(Calendar.DAY_OF_MONTH));
                    break;
                case MethodController.BOOLEAN_DIALOG_ID:
                    // pass
                    break;
                default:
                    ((EditText) dialog.findViewById(R.id.value)).setText(viewValue);
                    ((EditText) dialog.findViewById(R.id.value)).setInputType(controller.getInputType(selectedView));
                    dialog.setTitle(viewName);
                    break;
            }
        }
    }

    @Override
    protected Dialog onCreateDialog(int id) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setCancelable(true);
        View view = LayoutInflater.from(this).inflate(R.layout.dialog_layout, null);
        builder.setView(view);
        builder.setPositiveButton(R.string.set_button, mValueSetListener);
        builder.setNegativeButton(R.string.cancel_button, null);

        switch (id) {
            case MethodController.DATE_DIALOG_ID:
                Calendar c = Calendar.getInstance();
                return new DatePickerDialog(this, mDateSetListener,
                        c.get(Calendar.YEAR), c.get(Calendar.MONTH), c.get(Calendar.DAY_OF_MONTH));
            default:
                if (!(selectedView instanceof TextView)) {
                    builder.setTitle(((TextView) selectedView.findViewById(R.id.name)).getText());
                }
                break;
        }
        return builder.create();
    }

    /**
     * Composes method argument's views
     */
    private void composeLayout() {
        elementsLayout = (TableLayout) findViewById(R.id.argument_view_layout);
        ArrayList<View> views = controller.getViewList();
        for (View view : views) {
            elementsLayout.addView(view);
        }
    }

    /**
     * Returns listener for dialog show event
     *
     * @return listener for dialog show event
     */
    public View.OnClickListener getListener() {
        return mDialogShowListener;
    }

    /**
     * Adds passed view on the specified possition
     *
     * @param views    views to add on arguments layout
     * @param position first view position
     */
    public void addView(int position, View... views) {
        position++;  // +1 as title also takes position
        for (View view : views) {
            elementsLayout.addView(view, position++);
        }
    }
}