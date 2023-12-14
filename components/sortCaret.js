// 0: nothing, 1: ascending, 2: descending
export default function SortCaret({order, style}) {
    return (
        <span className="flex flex-column justify-around" style={style}>
            <svg width="10" height="6" xmlns="http://www.w3.org/2000/svg" fill={order === 1 ? "#F39C0F" : "darkgrey"}>
                <g>
                <title>Layer 1</title>
                <path transform="rotate(-180 5.06673 3.03996)" stroke="null" color="red" id="svg_1" d="m4.32153,5.78316c0.39567,0.39567 1.06772,0.39567 1.46339,0l4.05169,-4.05169c0.29122,-0.29122 0.37668,-0.72487 0.21841,-1.10472s-0.52545,-0.62675 -0.93695,-0.62675l-8.10339,0.00317c-0.40833,0 -0.77868,0.2469 -0.93695,0.62675s-0.06964,0.8135 0.21841,1.10472l4.0517,4.0517l-0.02631,-0.00317z"/>
                </g>
            </svg>
            <svg width="10" height="6" xmlns="http://www.w3.org/2000/svg" fill={order === 2 ? "#F39C0F" : "darkgrey"} style={{marginTop: 3}}>
                <g>
                <title>Layer 1</title>
                <path stroke="null" id="svg_1" d="m4.32153,5.78316c0.39567,0.39567 1.06772,0.39567 1.46339,0l4.05169,-4.05169c0.29122,-0.29122 0.37668,-0.72487 0.21841,-1.10472s-0.52545,-0.62675 -0.93695,-0.62675l-8.10339,0.00317c-0.40833,0 -0.77868,0.2469 -0.93695,0.62675s-0.06964,0.8135 0.21841,1.10472l4.0517,4.0517l-0.02631,-0.00317z"/>
                </g>
            </svg>
        </span>
    )
}