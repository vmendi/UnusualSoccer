package models;

import android.app.Activity;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.CheckBox;
import android.widget.TextView;
import com.example.R;
import controllers.AbstractController;

import java.lang.reflect.Type;

/**
 * Model for Boolean type of data
 * @author Yuri Samsoniuk
 */
public class BooleanArgInfo extends ArgInfo {
    /**
     * Constructor of the model
     * @param type of data represented by the model
     * @param activity  application activity
     * @param controller handling controller
     * @param padding padding of the main view
     */
    public BooleanArgInfo(Type type, Activity activity, AbstractController controller, int padding) {
        super(type, activity, controller, padding);
    }

    @Override
    public void createView(String name) {
        LayoutInflater inflater = LayoutInflater.from(activity);
        view = inflater.inflate(R.layout.boolean_view, null);
        TextView nameView = ((TextView) view.findViewById(R.id.name));
        nameView.setText(name);
        nameView.setPadding(nameView.getPaddingLeft() + padding, nameView.getPaddingTop(),
                nameView.getPaddingRight(), nameView.getPaddingBottom());
        ((TextView) view.findViewById(R.id.type)).setText(((Class) type).getSimpleName());
    }

    @Override
    public View getMainView() {
        return view;
    }

    @Override
    public Object getValue() {
        boolean isChecked = ((CheckBox) view.findViewById(R.id.value)).isChecked();
        if (Boolean.class.isAssignableFrom((Class<?>) type)) {
            return Boolean.valueOf(isChecked);
        }
        return isChecked;
    }

    @Override
    public void setValue(Object value) {
        ((CheckBox) view.findViewById(R.id.value)).setChecked((Boolean) value);
        view.findViewById(R.id.value).setClickable(false);
    }
}