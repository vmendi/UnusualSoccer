package models;

import android.app.AlertDialog;
import android.app.Activity;
import android.content.DialogInterface;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.TextView;
import com.example.R;
import controllers.AbstractController;

import java.lang.reflect.Type;

/**
 * Model for Enum data type
 *
 * @author Yuri Samsoniuk
 */
public class EnumArgInfo extends ArgInfo {
    /**
     * Enum items of the model type
     */
    private Object[] enums;
    /**
     * String values of enum items
     */
    private String[] enumStrings;
    /**
     * Index of selected enum in a list
     */
    private int selectedItemIndex = -1;
    /**
     * Listener for enum element choose dialog show
     */
    private final View.OnClickListener mDialogShowListener = new View.OnClickListener() {
        public void onClick(View view) {
            AlertDialog.Builder builder = new AlertDialog.Builder(activity);
            builder.setCancelable(true);
            builder.setSingleChoiceItems(enumStrings, selectedItemIndex, mValueSetListener);
            builder.setTitle(((TextView) view.findViewById(R.id.name)).getText());
            builder.show();
        }
    };
    /**
     * Listener for setting value of model to chosen value in a dialog
     */
    private final DialogInterface.OnClickListener mValueSetListener = new DialogInterface.OnClickListener() {
        public void onClick(DialogInterface dialogInterface, int i) {
            selectedItemIndex = i;
            ((TextView) view.findViewById(R.id.value)).setText(enumStrings[selectedItemIndex]);
            dialogInterface.dismiss();
        }
    };

    /**
     * Constructor of the model
     *
     * @param type       of data represented by the model
     * @param activity   application activity
     * @param controller handling controller
     * @param padding    padding of the main view
     */
    public EnumArgInfo(Type type, Activity activity, AbstractController controller, int padding) {
        super(type, activity, controller, padding);
    }

    @Override
    public void createView(String name) {
        LayoutInflater inflater = LayoutInflater.from(activity);
        view = inflater.inflate(R.layout.simple_type_view, null);
        TextView nameView = ((TextView) view.findViewById(R.id.name));
        nameView.setText(name);
        nameView.setPadding(nameView.getPaddingLeft() + padding, nameView.getPaddingTop(),
                nameView.getPaddingRight(), nameView.getPaddingBottom());
        ((TextView) view.findViewById(R.id.type)).setText(((Class) type).getSimpleName());
        enums = ((Class) type).getEnumConstants();
        enumStrings = new String[enums.length];
        for (int i = 0; i < enums.length; i++) {
            enumStrings[i] = enums[i].toString();
        }
        view.setOnClickListener(mDialogShowListener);
    }

    @Override
    public Object getValue() throws IndexOutOfBoundsException {
        return enums[selectedItemIndex];
    }

    @Override
    public void setValue(Object value) {
        TextView valueView = (TextView) view.findViewById(R.id.value);
        valueView.setText(String.valueOf(value));
        view.setClickable(false);
    }
}
