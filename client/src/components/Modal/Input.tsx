import React, { FC } from 'react';
import OtpInput from 'react-otp-input';
import CSS from 'csstype';

interface Props {
  value?: string;
  onChange: React.Dispatch<React.SetStateAction<string>>;
  type?: string;
  numInputs: number;
}

const InputStyle: CSS.Properties = {
  width: '3rem',
  height: '4rem',
  margin: '0 0.3rem',
  color: 'black',
  background: 'white',
  border: 'none',
  borderRadius: '8px',
  fontSize: '20px',
};

const Input: FC<Props> = ({ value, onChange, numInputs }) => (
  <OtpInput
    value={value}
    onChange={onChange}
    numInputs={numInputs}
    separator={<span>-</span>}
    inputStyle={InputStyle}
    shouldAutoFocus
  />
);

export default Input;
