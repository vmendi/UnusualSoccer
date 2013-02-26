package models;

import android.app.Activity;
import android.text.InputType;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.TextView;
import com.example.R;
import controllers.AbstractController;

import java.lang.reflect.Type;

/**
 * Model for primitive type of data
 *
 * @author Yuri Samsoniuk
 */
public class PrimitiveArgInfo extends ArgInfo {
    /**
     * Input types for input data dialog
     */
    private final int INTEGER_INPUT_TYPE = InputType.TYPE_CLASS_NUMBER | InputType.TYPE_NUMBER_FLAG_SIGNED;
    private final int FLOATING_POINT_INPUT_TYPE = InputType.TYPE_CLASS_NUMBER
            | InputType.TYPE_NUMBER_FLAG_DECIMAL | InputType.TYPE_NUMBER_FLAG_SIGNED;
    private final int STRING_INPUT_TYPE = InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE;

    /**
     * Constructor of the model
     *
     * @param type       of data represented by the model
     * @param activity    application activity
     * @param controller handling controller
     * @param padding    padding of the main view
     */
    public PrimitiveArgInfo(Type type, Activity activity, AbstractController controller, int padding) {
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
        view.setOnClickListener(controller.getListener());
    }

    @Override
    public Object getValue() throws NumberFormatException {
        Class clazz = (Class) type;
        String value = ((TextView) view.findViewById(R.id.value)).getText().toString();
        if (clazz.isPrimitive()) {
            if (Integer.TYPE.isAssignableFrom(clazz)) {
                return Integer.parseInt(value);
            } else if (Long.TYPE.isAssignableFrom(clazz)) {
                return Long.parseLong(value);
            } else if (Short.TYPE.isAssignableFrom(clazz)) {
                return Short.parseShort(value);
            } else if (Byte.TYPE.isAssignableFrom(clazz)) {
                return Byte.parseByte(value);
            } else if (Double.TYPE.isAssignableFrom(clazz)) {
                return Double.parseDouble(value);
            } else if (Float.TYPE.isAssignableFrom(clazz)) {
                return Float.parseFloat(value);
            }
        } else {
            if (Integer.class.isAssignableFrom(clazz)) {
                return Integer.valueOf(value);
            } else if (Long.class.isAssignableFrom(clazz)) {
                return Long.valueOf(value);
            } else if (Short.class.isAssignableFrom(clazz)) {
                return Short.valueOf(value);
            } else if (Byte.class.isAssignableFrom(clazz)) {
                return Byte.valueOf(value);
            } else if (Double.class.isAssignableFrom(clazz)) {
                return Double.valueOf(value);
            } else if (Float.class.isAssignableFrom(clazz)) {
                return Float.valueOf(value);
            } else if (clazz.isArray() && Character.TYPE.isAssignableFrom(clazz.getComponentType())) {
                return value.toCharArray();
            } else if (StringBuilder.class.isAssignableFrom((Class<?>) type)) {
                return new StringBuilder(value);
            }
        }
        return value;
    }

    @Override
    public void setValue(Object value) {
        TextView valueView = (TextView) view.findViewById(R.id.value);
        valueView.setHint(R.string.empty);
        if (((Class<?>) type).isArray() && Character.TYPE.isAssignableFrom(((Class<?>) type).getComponentType())) {
            valueView.setText(String.valueOf(new String((char[]) value)));
        } else {
            valueView.setText(String.valueOf(value));
        }
        view.findViewById(R.id.value).setClickable(false);
    }

    @Override
    public int getInputType(View view) {
        Class clazz = (Class) type;
        if (Integer.class.isAssignableFrom(clazz) || Integer.TYPE.isAssignableFrom(clazz)
                || Long.class.isAssignableFrom(clazz) || Long.TYPE.isAssignableFrom(clazz)
                || Short.class.isAssignableFrom(clazz) || Short.TYPE.isAssignableFrom(clazz)
                || Byte.class.isAssignableFrom(clazz) || Byte.TYPE.isAssignableFrom(clazz)) {
            return INTEGER_INPUT_TYPE;
        } else if (Double.class.isAssignableFrom(clazz) || Double.TYPE.isAssignableFrom(clazz)
                || Float.class.isAssignableFrom(clazz) || Float.TYPE.isAssignableFrom(clazz)) {
            return FLOATING_POINT_INPUT_TYPE;
        } else {
            return STRING_INPUT_TYPE;
        }
    }
}